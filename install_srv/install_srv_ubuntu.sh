#!/bin/bash

OS=`lsb_release -i | cut -f2`

if [ $OS != "Debian" ] && [ $OS != "Ubuntu" ]; then
	echo "Установка возможна лишь на операционные системы Debian, Ubuntu. Воспользуйтесь другим скриптом для вашей ос ($OS)."
	exit 0
fi

# Путь установки
path=""
steamcmd_path=""

echo -e "Проверяю наличие необходимых пакетов"

if [[ ! `dpkg --get-selections | grep -w wget | grep install` ]]
	then
		echo -e "Утилита wget не установлена, будет выполнена установка"
		apt-get install wget
fi

if [[ ! `dpkg --get-selections | grep -w sudo | grep install` ]]
	then
		echo -e "Утилита sudo не установлена, будет выполнена установка"
		apt-get install sudo
fi

if [[ ! `dpkg --get-selections | grep -w unzip | grep install` ]]
	then
		echo -e "Утилита unzip не установлена, будет выполнена установка"
		apt-get install unzip
fi

if [[ ! `dpkg --get-selections | grep -w tar | grep install` ]]
	then
		echo -e "Утилита tar не установлена, будет выполнена установка"
		apt-get install tar
fi

if [[ ! `dpkg --get-selections | grep -w ssh | grep install` ]]
	then
		echo -e "Утилита ssh не установлена, будет выполнена установка"
		apt-get install ssh
		service ssh start
fi

if [[ ! `dpkg --get-selections | grep -w screen | grep install` ]]
	then
		echo -e "Утилита screen не установлена, будет выполнена установка"
		apt-get install screen
fi

while [ "$path" == "" ]
do
	read -p "Введите путь установки исполняемых файлов GameAP: " -e -i "/home/servers" path
	
	if [ "$path" == "" ]; then
		echo -e "Не введена директория для установки файлов GameAP!"
		continue
	fi
	
	if [ ! -d "$path" ]; then
		echo -e "Указанной директории не существует ($path)"
		echo -n "Создать директорию? (y/n): "
		
		read question
		if [ "$question" == "y" -o "$question" == "Y" ]; then
			mkdir $path
			if [ ! -d "$path" ]; then
				echo -e "Не удалось создать директорию $path"
				path=""
			fi
				
		else
			path=""
		fi
	fi
done

while [ "$steamcmd_path" == "" ]
do
	read -p "Введите путь установки SteamCMD: " -e -i "/home/servers/steamcmd" steamcmd_path
	
	if [ "$steamcmd_path" == "" ]; then
		echo -e "Не введена директория для установки файлов SteamCMD!"
		continue
	fi
	
	if [ ! -d "$steamcmd_path" ]; then
		echo -e "Указанной директории не существует ($steamcmd_path)"
		echo -n "Создать директорию? (y/n): "
		
		read question
		if [ "$question" == "y" -o "$question" == "Y" ]; then
			mkdir $steamcmd_path
			if [ ! -d "$steamcmd_path" ]; then
				echo -e "Не удалось создать директорию $steamcmd_path"
				path=""
			fi
				
		else
			path=""
		fi
	fi
done

echo -e "Путь установки исполняемых файлов GameAP: $path"
echo -e "Путь установки SteamCMD: $steamcmd_path"

cd $path
echo -e "Начинаю загрузку файлов GameAP"
wget http://www.gameap.ru/files/srv/gameap_exec.zip
unzip -o gameap_exec.zip && rm gameap_exec.zip
chmod +x server.sh

cd $steamcmd_path
echo -e "Начинаю загрузку файлов SteamCMD"
wget http://www.gameap.ru/files/srv/steamcmd.zip
unzip -o steamcmd.zip && rm steamcmd.zip
chmod +x steamcmd.sh

MATRIX="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
while [ "${n:=1}" -le 12 ]
do
        PASS="$PASS${MATRIX:$(($RANDOM%${#MATRIX})):1}"
        let n+=1
done

groupadd gameap
useradd -d $path -s /bin/bash -g gameap gameap
echo "gameap:$PASS"|chpasswd

chown -R gameap:gameap $path
chown -R gameap:gameap $steamcmd_path

# Конфигурирование SSH сервера
cp sshd_config sshd_config_backup
sed 's/^AllowUsers .*$/& gameap/' /etc/ssh/sshd_config_backup >sshd_config
service ssh restart

echo "gameap ALL = NOPASSWD: $path/server.sh" >> /etc/sudoers
echo "gameap ALL = NOPASSWD: $steamcmd_path/steamcmd.sh" >> /etc/sudoers

# Открытие некоторых портов
iptables -I INPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -I INPUT -p tcp --dport 27000:27099 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -I INPUT -p udp --dport 27000:27099 -m state --state NEW,ESTABLISHED -j ACCEPT

echo -e ""
echo -e "----------------------------------------"
echo -e "Зайдите в панель управления, перейдите в Серверы->Выделенные серверы->Добавить сервер"
echo -e "Укажите следующие параметры:"
echo -e " Имя: <любое>"
echo -e " Операционная система: Linux"
echo -e " Расположение: <Укажите локацию выделенного сервера>"
echo -e " Провайдер: <Укажите вашего провайдера>"
echo -e " IP: <Укажите IP этого сервера>"
echo -e "\n --Параметры доступа к серверу--"
echo -e " Путь к корневой директории с исполняемыми файлами GameAP (server.sh или server.exe): $path"
echo -e " Путь к SteamCMD: $steamcmd_path"
echo -e " Протокол управления сервером: SSH"
echo -e "\n --FTP данные--"
echo -e " Оставьте все пустым"
echo -e "\n --SSH данные--"
echo -e " Хост SSH(IP:port): <Укажите IP этого сервера>"
echo -e " Логин: gameap"
echo -e " Пароль: $PASS"
echo -e "\n --Telnet данные--"
echo -e " Оставьте все пустым"

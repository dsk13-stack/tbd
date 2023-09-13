#!/bin/bash

# Скрипт для получения внешнего IP адреса и отправки его на email
# Для корректной работы необходимы: OpenDNS и msmtp

# Путь к файлу логов
LOG_FILE=/var/log/ip_update.log

# Путь к файлу с текущим адресом
IP_FILE=/tmp/ip_update.tmp

# Путь к файлу с ошибками выполнения
ERROR_FILE=/tmp/ip_update_errors.tmp

# Текущая дата в формате'%F %T'
NOW=$(date +'%F %T')

# Перенаправление stderr в ERROR_FILE
exec 2>$ERROR_FILE

# Проверка создан ли файл логов, если нет то создаем его
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
fi

# Функция для записи логов
function write_log() {
    echo "$NOW: $*" >> $LOG_FILE
}

# Функция получения внешнего IP
function get_external_ip() {    
    local ip
    # Получаем внешний IP с помощью OpenDNS. 
    # В случае ошибки записываем в лог и завершаем работы с кодом ошибки
    if ! ip=$(dig @resolver4.opendns.com myip.opendns.com +short -4); then
        write_log "Ошибка получения внешнего IP"
        exit 1
    fi
    echo "$ip"
}

# Проверка наличия файла с IP адресом
if [ ! -f "$IP_FILE" ]; then
    # Если файла нет, создаем его и записываем в него текущий адрес
    touch "$IP_FILE"
    get_external_ip > "$IP_FILE"
    # Отпраляем новый адрес с помощью msmtp
    msmtp -a default user@gmail.com < "$IP_FILE" || write_log "Ошибка отправки email"
else
    # Если файл есть сравниваем IP из файла и текущий
    last_ip=$(cat "$IP_FILE")
    current_ip=$(get_external_ip) 
    if [ "$last_ip" != "$current_ip" ]; then
        # Если есть отличия, обновляем файл и отправляем новый адрес на email
        echo "$current_ip" > "$IP_FILE"
        msmtp -a default dsk13@inbox.ru < "$IP_FILE" || write_log "Ошибка отправки email"
    fi
fi



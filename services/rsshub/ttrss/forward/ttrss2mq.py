#!/usr/bin/python3
import pika
import json
import os
import requests
import re
from requests.auth import HTTPBasicAuth

# 设置RabbitMQ连接参数
# rabbitmq_host = 'amqp.cicd.getdeepin.org'
# rabbitmq_port = 32672
# rabbitmq_username = 'user'
# rabbitmq_password = ''
# rabbitmq_queue = 'deepin-ttrss'
rabbitmq_host = os.environ.get('rabbitmq_host')
rabbitmq_port = os.environ.get('rabbitmq_port')
rabbitmq_username = os.environ.get('rabbitmq_username')
rabbitmq_password = os.environ.get('rabbitmq_password')
rabbitmq_queue = os.environ.get('rabbitmq_queue')

# 创建RabbitMQ连接

ttrss_host = os.environ.get('TTRSSHOST')
ttrss_username = os.environ.get('TTRSSUSER')
ttrss_password = os.environ.get('TTRSSPASS')

# 获取ttrss sid
# url: https://ttrss.cicd.getdeepin.org/ 
def get_ttrss_sid(url, usr, passwd):
    data = {
        "op": "login",
        "user": usr,
        "password": passwd
    }
    response = requests.post(url, json=data)
    data = json.loads(response)
    sid = ""
    content = data.get("content", "")
    if content != "":
        sid = content.get("session_id","")
    return sid

def send_to_rabbitmq(content):
    # 修改这里的参数值，使其与队列的当前设置相匹配
    args = {
        'durable': True  # 确保这里的值为True或False，与队列的当前设置相匹配
    }
    # 连接到RabbitMQ服务器
    credentials = pika.PlainCredentials(rabbitmq_username, rabbitmq_password)
    parameters = pika.ConnectionParameters(host=rabbitmq_host, port=rabbitmq_port, credentials=credentials,
                    heartbeat=0, connection_attempts=3, socket_timeout=300)
    connection = pika.BlockingConnection(parameters)
    channel = connection.channel()

    # 声明一个队列
    channel.queue_declare(queue=rabbitmq_queue, durable=args['durable'], arguments=args)

    # 将content数组转换为JSON字符串
    content_json = json.dumps(content)

    # 将JSON字符串发送到队列
    channel.basic_publish(exchange='', routing_key=rabbitmq_queue, body=content_json)
    print(" [x] Sent %r" % content_json)

    # 关闭连接
    connection.close()

def get_ttrss_unread(url, sid, feed_id):
    data = {
        "op": "getHeadlines",
        "sanitize": True,
        "limit": 10,
        "feed_id": feed_id,
        "sid": sid
    }

    return requests.post(url, json=data)

def set_ttrss_read(url, sid, ids, field):
    data = {
        "op": "updateArticle",
        "article_ids": ids,
        "mode": 0,
        "field": field,
        "sid": sid
    }
    return requests.post(url, json=data)

if __name__ == "__main__":
    sid = get_ttrss_sid(ttrss_host, ttrss_username, ttrss_password)
    uneads = get_ttrss_unread(ttrss_host, sid, feed_id)
    for unead in uneads:
        send_to_rabbitmq(unead)
        set_ttrss_read(ttrss_host, sid, unead.id, unead.field)

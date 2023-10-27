#!/usr/bin/python3

import pika
import json
import os
import shutil

# 设置RabbitMQ连接参数
rabbitmq_host = 'amqp.cicd.getdeepin.org'
rabbitmq_port = 32672
rabbitmq_username = 'user'
rabbitmq_password = ''
rabbitmq_queue = 'obs-src'

# 创建RabbitMQ连接
credentials = pika.PlainCredentials(rabbitmq_username, rabbitmq_password)
parameters = pika.ConnectionParameters(host=rabbitmq_host, port=rabbitmq_port, credentials=credentials)
connection = pika.BlockingConnection(parameters)
channel = connection.channel()

# 修改这里的参数值，使其与队列的当前设置相匹配
args = {
    'durable': True  # 确保这里的值为True或False，与队列的当前设置相匹配
}

# 声明队列
channel.queue_declare(queue=rabbitmq_queue, durable=args['durable'], arguments=args)

# 定义回调函数处理消息
def callback(ch, method, properties, body):
    event = json.loads(body)
    if event['table'] == "events" and event['database'] == "api_production":
        #print("接收到OBS事件: ", event)
        if len(event['data']) > 0:
            #print("event_data: ", event['data'])
            event_data = event['data'][0]
            event_data_type = event_data['eventtype']
            event_data_payload = json.loads(event_data['payload'])
            #print("event_data_type: ", event_data_type, "\n event_data_payload: ", event_data_payload)
            # TODO: obs的BuildFail事件在obs软件包构建完成后会响应三次，应该是和obs的调度机制有关系，
            # 目前通过undone_jobs=1进行过滤,或许有更好的过滤方法？
            #print(event_data)
            #print("undoe_jobs: ", undone_jobs)
            undone_jobs = event_data.get('undone_jobs')

            #  事件类型为Event::Build开头的是构建事件，可以通过过滤处理
            if "Event::Build" in event_data_type and undone_jobs == '1':
                print(event_data)
                project = event_data_payload['project']
                package = event_data_payload['package']
                repository = event_data_payload['repository']
                arch = event_data_payload['arch']

                if "deepin:CI" in project and "deepin:CI:TestingIntegration" not in project:
                    print("Filted OBS CI building envent at ", project)
                    # TODO: 等待对接明道云的webhook流程

# 开始消费队列中的消息
channel.basic_consume(queue=rabbitmq_queue, on_message_callback=callback, auto_ack=True)

print('开始监控队列，按Ctrl+C退出')
channel.start_consuming()

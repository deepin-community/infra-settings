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
            # 忽略deepin:CI的错误日志
            if event_data_type == "Event::BuildFail" and undone_jobs == '1':
                project = event_data_payload['project']
                package = event_data_payload['package']
                repository = event_data_payload['repository']
                arch = event_data_payload['arch']
                rev = event_data_payload['rev']
                if  "deepin:CI" not in project:
                    print(event_data)
                    #print(project, package, repository, arch, rev)
                    src_log_path = os.path.join("/srv/obs/build/", project, repository, arch, package)
                    src_log_path_file = os.path.join(src_log_path, "logfile")
                    dest_log_path = os.path.join("/srv/obs/repos/errlogbak/", project, repository, arch, package, rev)
                    dest_log_path_file = os.path.join(dest_log_path, "logfile.txt")
                    if not os.path.exists(dest_log_path):
                        os.makedirs(dest_log_path)
                    if os.path.exists(src_log_path_file):
                        shutil.copy(src_log_path_file, dest_log_path_file)
                    else:
                        print("Warn: %s not exists" % src_log_path_file)

# 开始消费队列中的消息
channel.basic_consume(queue=rabbitmq_queue, on_message_callback=callback, auto_ack=True)

print('开始监控队列，按Ctrl+C退出')
channel.start_consuming()

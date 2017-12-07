from __future__ import print_function
from configparser import ConfigParser, ParsingError
from fire import Fire
from docker import DockerClient
import jinja2
# client = docker.DockerClient(base_url='tcp://YCSB-PUBLIC-IP:2375')


config = ConfigParser()


class YcsbTest(object):
    """
    YCSB Test Runner Class
    Usage:
    python ycsb.py run --html=True --config_file='ycsb_conf.dat' --docker_host='10.0.0.16'
    Or via docker socks on local machine:
    python ycsb.py run --html=True --config_file'ycsb_conf.dat'
    Want the results printed to stdout rather than a HTML file?
    python ycsb.py run --html=Flase --stdout=True
    """

    def __init__(self,
                 docker_host='unix:///var/run/docker.sock',
                 config_file='ycsb_conf.dat'):
        self.docker_client = DockerClient(base_url=docker_host)
        self.config = config
        self.config.read(config_file)
        self.servers = self._parse_servers()
        self.workloads = self._parse_workloads()
        self.ycsb_param = self._parse_ycsb_parameters()

    def command(self, kind='load', server='redis', workload='workloada'):
        ip = self.servers.get(server)
        if 'elasticache' in server:
            server = 'redis'
            auka = '-p "redis.host=%(ip)s"' %locals()
        elif 'aerospike' in server:
            auka = '-p "as.host=%(ip)s"' %locals()
        else:
            auka = '-p "%(server)s.host=%(ip)s"' %locals()
        param = self._parse_ycsb_parameters()
        return '%(kind)s %(server)s -s %(param)s -P workloads/%(workload)s %(auka)s' %locals()

    def run(self, ycsb_img='donchev7/alpine-ycsb:0.12.0', html=True, stdout=False):
        if self._has_missing_fields():
            raise ParsingError(filename=config_file)
        results = []
        for server in self.servers:
            print('Loading server: %(server)s\n' %locals())
            load = self.docker_client.containers.run(
                image=ycsb_img,
                init=True,
                network_mode='host',
                command=self.command(kind='load', server=server)
            ).decode('utf8')
            latencies = self._extract_latencies(load, op='INSERT')
            results.append({
                'server': server,
                'workload': 'workloada',
                'op': 'INSERT',
                'throughput': self._extract_throughput(load),
                'latencies': self._extract_results(
                    op='INSERT', latencies=latencies)
            })
            for workload in self.workloads:
                print('Running %(workload)s on server: %(server)s\n' %locals())
                load = self.docker_client.containers.run(
                    image=ycsb_img,
                    init=True,
                    network_mode='host',
                    command=self.command(kind='run', server=server)
                ).decode('utf8')
                for op in ['READ', 'UPDATE']:
                    latencies = self._extract_latencies(load, op=op)
                    results.append({
                        'server': server,
                        'workload': workload,
                        'op': op,
                        'throughput': self._extract_throughput(load),
                        'latencies': self._extract_results(
                            op='INSERT', latencies=latencies)
                    })

        if html:  # write to HTML
            with open('results.html', 'w') as f:
                workloads = list({s['workload'] for s in results})
                workload_ops = {}
                for workload in workloads:
                    workload_ops[workload] = [s for s in results if s['workload'] == workload]
                context = {
                    'workloads': workloads,
                    'workload_ops': workload_ops
                    }
                f.write(self._render_html(context=context))
        if stdout:  # print to terminal
            print(results)
        return 'Finshed tests'

    def _has_missing_fields(self):
        return bool(set(self.config.sections()) - set(['YCSB',
                                                       'SERVER',
                                                       'WORKLOAD']))

    def _parse_ycsb_parameters(self):
        return ' '.join(
            ["-p {0}={1}".format(key, config['YCSB'][key])
             for key in config['YCSB'].keys()])

    def _parse_servers(self):
        return {key: config['SERVER'][key] for key in config['SERVER'].keys()}

    def _parse_workloads(self):
        workloads = [key for key in config['WORKLOAD'].keys()]
        if 'all' in workloads:
            return ['workload'+i for i in ['a', 'b', 'c', 'd', 'e', 'f']]
        return workloads

    @staticmethod
    def _extract_throughput(result):
        return round(
            float(
                ''.join(
                        [s.split(',')[2] for s in result.split('\n')
                         if 'Throughput(ops/sec)' in s]
                        )
                  ), 1)

    @staticmethod
    def _extract_latencies(result, op='INSERT'):
        return [s for s in result.split('\n')
                if op in s and 'Latency' in s]

    @staticmethod
    def _extract_results(op='READ', latencies=[]):
        if len(latencies) == 0:
            raise Exception('Cant extract results check the loads')
        return {
                'avg': round(float(latencies[0].split(',')[2])/1000, 2),
                'min': round(float(latencies[1].split(',')[2])/1000, 2),
                'max': round(float(latencies[2].split(',')[2])/1000, 2),
                '95p': round(float(latencies[3].split(',')[2])/1000, 2),
                '99p': round(float(latencies[4].split(',')[2])/1000, 2)
            }

    @staticmethod
    def _render_html(tpl='results.jinja2', context={}):
        return jinja2.Environment(
            loader=jinja2.FileSystemLoader('./')
        ).get_template(tpl).render(context)


if __name__ == '__main__':
    Fire(YcsbTest)




共两个文件SSHelper.pm和runssh
放到一个目录即可
 
 
批量执行：
runssh用法：
./runssh --hosts host.txt --cmd "ls /root"
./runssh --hsots host.txt --src "test.cpp" --dst "/root" --cmd "gcc test.cpp -o test"
 
host.txt内容例子:
127.0.0.1 pass
10.18.20.1 12345
 
差异批量执行：
 
./runssh --hosts host.txt --cmds cmd.txt
 
cmd.txt:
127.0.0.1 ls /root
10.18.20.1  zypper -n install gcc


SSHelper.pm

实现通过SSH管理集群的简单工具

可以批量复制文件、批量执行命令

用法实例：

perl -MSSHelper -e 'SSHelper::batch_run('hosts.txt', "/root/test", "test", "/root");

将test复制到远程机器中/root目录下，并执行。

hosts.txt保存了所有机器的IP和root用户密码。

如：

10.10.10.1 adminpass

10.10.10.2 secccc


killit
杀一种木马
nohup ./killit /tmp &

监控发现有进程在/tmp目录创建文件，则杀死该进程
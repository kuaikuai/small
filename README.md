
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
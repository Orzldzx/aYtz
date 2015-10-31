# 德州手机/tv日常维护操作手册


**登录`192.168.7.230`主机**
## 预发布
#### 版本发布
- 增量发布
 - 执行 `/auto-publish/tex/yfb/tex-yfb-hot.sh`
 - 登录预发布服务器执行 `cd /svndata && ./server.sh [reload|restart|start|stop|status] [svrname]`


- 全量发布
 - 执行 `/auto-publish/tex/yfb/tex-yfb-all.sh`
 - 登录预发布服务器执行 `cd /svndata && ./server.sh [reload|restart|start|stop|status] [svrname]`


## 生产
#### 版本发布
- 增量发布
 - 执行 `/auto-publish/tex/sc/tex-yfb-hot.sh`
 - 登录相关服务器依次执行 `cd /svndata && ./server.sh [reload|restart|start|stop|status] [svrname]`


- 全量发布
 - 执行 `/auto-publish/tex/sc/tex-yfb-all.sh`
 - 登录相关服务器依次执行 `cd /svndata && ./server.sh [reload|restart|start|stop|status] [svrname]`


#### 配置更新
- 点击下方链接输入指定svn版本号更新
> [更新配置地址](http://192.168.7.230:8091/set.php), 登录相关服务器依次执行 `cd /svndata && ./server.sh [reload|restart|start|stop|status] [svrname]`


#### 自动增量发布
- 登录`192.168.7.132`
 - _web页面暂未准备好,可使用crontab执行定时自动发布_
*需要在SvrList.txt文件里配置需要重启和重载的服务名称*
   - 手动执行
    `/shell/auto-push/auto-tex.sh [svn版本号]`
   - 定时执行
```shell
#cat /etc/crontab
30 8	24 9 *	root	/tex-shell/auto-tex.sh [svn版本号] &> /tmp/auto-tex.$(date +\%m\%d)
```


#### rundeck
> [登录地址](http://192.168.7.132:4440)
> 帐号: *dm**
> 密码: a***n**mi*

德州生产使用的项目有三个
1. tex-reload
 - 功能: 更新配置,发布版本,重载服务
2. tex-admin
 - 功能: 更新配置,发布版本,重启服务
3. tex-cnd
 - 更新cdn文件
    - 通过ftp把文件同步到`192.168.7.132:/alidata1/nginx/ksyun/texas/download`目录下
    - 点击web页面操作更新到外网cdn


***# Rundeck服务搭建在`192.168.7.132`服务器上***

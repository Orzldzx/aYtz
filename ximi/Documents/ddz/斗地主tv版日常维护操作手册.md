# 斗地主tv版日常维护操作手册


## 预发布
#### 版本发布

- 登录`192.168.7.230`执行: 
```shell
/lzqcfg.test/ddz/tv-pre/unzip.sh
/lzqcfg.test/ddz/tv-pre/rsync_online_tv-pre.sh
```

- 登录阿里云跳板机`121.199.41.80`执行:
 - 全量发布
> `/lzqcfg.test/tv-pre/generate_cfg.sh out send del`
 - 增量发布
> `/lzqcfg.test/tv-pre/hot/ddz_generate_TV.sh.hot`

- 依次登录相关服务器重启/重载服务进程


## 生产
#### 版本发布

- 登录`192.168.7.230`执行:
```shell
/lzqcfg.product/ddz/online-tv/unzip.sh
/lzqcfg.product/ddz/online-tv/rsync_online_tv.sh
```

- 登录阿里云跳板机`121.199.41.80`执行:
 - 全量发布
> `/lzqcfg.product/ddz/online-tv/generate_cfg.sh out send del`
 - 增量发布
> `/lzqcfg.product/ddz/online-tv/hot/ddz_generate_TV.sh.hot`

- 依次登录相关服务器重启/重载服务进程

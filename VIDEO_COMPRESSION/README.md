# 便捷压制 By.Chinshry

[![Badge](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Chinshry/CBash/tree/main/VIDEO_COMPRESSION)
[![Badge](https://img.shields.io/badge/Gitee-C71D23?style=for-the-badge&logo=gitee&logoColor=white)](https://gitee.com/chinshry/CBash/tree/main/VIDEO_COMPRESSION)

## 目录

* [💻 环境准备](#-环境准备)
* [💾 压制](#-压制)
  * [1️⃣ 合轴](#1️⃣-合轴)
  * [2️⃣ 压制配置](#2️⃣-压制配置)
  * [3️⃣ 普通压制](#3️⃣-普通压制)
  * [4️⃣ AVS压制](#4️⃣-AVS压制)
  * [5️⃣ 归档](#5️⃣-归档)
* [❗ 注意事项](#-注意事项)
* [❓ Q&A](#-qa)

## 💻 环境准备

### 下载所需文件

| 文件 | 下载地址(蓝奏 密码:0710) |
| ----- | ------ |
| @@压制工作站.zip | https://wwxi.lanzouq.com/b01rb3ucf |
| @@压制工作站_no_ffmpeg.zip | https://wwxi.lanzouq.com/b01rb3ucf |

### 无需配置ffmpeg环境变量(二选一)

1. 下载 [@@压制工作站.zip]；
2. 下载后解压，然后放置，以后该目录作为**压制工作目录**；

### 需要配置ffmpeg环境变量(二选一)

1. 下载 [@@压制工作站_no_ffmpeg.zip]
2. 下载后解压，然后放置，以后该目录作为**压制工作目录**；
3. 下载 [ffmpeg稳定版](https://github.com/GyanD/codexffmpeg/releases/download/6.0/ffmpeg-6.0-full_build.zip)；
4. 按照 [环境变量配置教程](https://www.bilibili.com/read/cv13908332) 配置ffmpeg环境变量；

## 💾 压制

### 1️⃣ 合轴

#### 1. 加滚轴行

* [做不完的工作统计] (链接见群公告) 对应视频的分表里复制，或自行编写添加；
* 将滚轴行添加到轴文件第一行；

#### 2. 加LOGO行

* [@@LOGO行Vxxxxxx.txt] 里按视频分辨率复制，复制后也可根据遮挡情况自行调整大小(横版1:0.4 | 方版 1:1)；或自行编写添加，示例以及说明如下：
  > * \pos{x,y} | 以左上角为锚点调整位置  
  > * m 0 0 l w 0 w h 0 h | Logo大小，注意两个w和h均需要修改为宽高  
  > * logo_fang.png | Logo文件名，放置于 res\logo 目录下

  ```ass
  Dialogue: 0,0:00:00.00,5:00:00.00,横1080_听轴,,0,0,0,,{\an7\bord0\c&ffffff\p1\pos(200,30)\fs20}m 0 0 l 250 0 250 100 0 100{\p0}logo_heng.png
  ```

* 注释勾选框放开调整位置，调整完勾上注释；
* 添加到轴文件第一行(滚轴行之前)；
* 查看滚轴和LOGO是否打架，酌情调整；

### 2️⃣ 压制配置

* 配置文件 [@@config.txt] 可进行如下配置

> 一般使用默认配置即可，无需修改。如有修改，修改完毕后一定要保存：

| 属性名 | 默认值 | 描述 | 备注 |
| ----- | ------ | ------ | ------ |
| AVSMode | 0 | 是否AVS压制 | 本次压制完毕后，修改回0 |
| NeedLogo | 1 | 是否压制Logo | 本次压制完毕后，修改回0 |
| NeedYadif | 0 | 是否反交错 | 视频源为INDEX的 **打歌舞台** 或视频源播放有 **拉丝现象** 时需要修改为1，本次压制完毕后，修改回0 |
| CRF | 18 | CRF | 推荐配置范围18-25，数字越小越接近无损，18为几乎无损，[参考资料](https://trac.ffmpeg.org/wiki/Encode/H.264#a1.ChooseaCRFvalue)；若高码率含舞台的视频可压制30s，观察损耗是否严重，再酌情调整 |
| GraphicsType | i | 压制类型 | 类型，若GPU为n卡可修改为n，压制更快 |

### 3️⃣ 普通压制

1. 将视频和轴文件直接拖拽到 [@字幕压制Vxxxxxx.bat] 脚本上。
2. 脚本执行后会确认配置项，确认无误后回车开始压制。

### 4️⃣ AVS压制

> * 凡用到vsfiltermod的标签需用AVS压制, 即 [标准文档](https://aegi.vmoe.info/docs/3.2/ASS_Tags/) 内未提及的标签 例如：\$img \vc \fsvp  
> * 所有vsfiltermod标签在文档内查阅： [vsfiltermod手册简要介绍目录](https://cwlrin.wiki/wp-content/uploads/2021/02/vsfiltermod-%E6%89%8B%E5%86%8C.pdf)
> * AVS压制会复制一份视频到临时目录，因此必须保证 工作目录可用空间 > 视频所占用空间

1. 下载并安装 [AviSynthPlus](https://github.com/AviSynth/AviSynthPlus/releases/download/v3.7.3/AviSynthPlus_3.7.3_20230715.exe) 必须勾选X64
![picture](https://gitee.com/chinshry/CBash/raw/main/VIDEO_COMPRESSION/Capture/AviSynthPlus.png)
2. 配置文件[config.txt] 中的AVSMode配置为1
3. 其余步骤同普通压制，将视频和轴拖拽到脚本即可
4. 压制完毕后请记得将AVSMode修改回0

### 5️⃣ 归档

压制结束后把视频和轴都放到共享文件夹[做不完中转站]相应视频项目内(百度共享网盘，分享链接24h失效，请在群内询问)，命名为：  
中字：{date} {videoName} 中字.mp4  例如：230729 音乐中心 中字.mp4  
合轴：{date} {videoName} 合轴.ass  例如：230729 音乐中心 合轴.ass  

## ❗ 注意事项

* LOGO行
  * 不要动\an7
  * 调整完位置，注释一定要勾选上，确保无白方块存在
* 滚轴行
  * 尽量直接复制表格内容，否则容易不滚动活着样式错乱。
* 压制
  * 可以先压30s，然后将压制窗口叉掉看看滚轴和LOGO是否有问题，花字是否对帧。
  * 拉丝现象可使用Potplayer播放器关闭反交错优化观察(视频上右键 视频-反交错-不使用)，同时腾讯文档该视频的表格内会有显著标注。
    * 拉丝现象如下：
    ![picture](https://gitee.com/chinshry/CBash/raw/main/VIDEO_COMPRESSION/Capture/YadifExample.png)
  * 压制时，可以通过以下变量估算压制进度：
    * frame：已经压制的帧数，frame / 视频总帧数 = 压制进度
    * time：已经压制的视频时长， time / 视频总时长 = 压制进度
    * speed：压制速度，视频时长/speed ≈ 压制所需总时长。不是绝对速度，根据电脑配置，视频码率各有差异。
    ![picture](https://gitee.com/chinshry/CBash/raw/main/VIDEO_COMPRESSION/Capture/Progress.png)

## ❓ Q&A

### Q1. 遇到闪退

录制操作过程视频发到群里

### Q2. 提示“chcp不是内部或外部命令”显示乱码

![picture](https://gitee.com/chinshry/CBash/raw/main/VIDEO_COMPRESSION/Capture/Q2.png)

在系统变量PATH下添加路径C:\WINDOWS\system32;  [具体教程](https://blog.csdn.net/stupid_dernier/article/details/85105117)

### Q3. 提示“没有找到符合条件的LOGO行”

* 检查logo行是否在第一行
* 检查logo行末尾是否有logo_fang.png或者logo_heng.png

### Q4. 2K/4K(VP90)视频压制多了一个pre文件

正常现象，是VP90视频的中间文件。  
压制中不要对该文件进行任何改动，压制完毕后可以删除。

### Q5. 2K/4K(VP90)视频压制出来没有声音

下载安装Potplayer，再次查看视频

* 官网(梯)：<https://potplayer.daum.net/?lang=zh_CN>
* 镜像：<http://potplayer.tv/?lang=zh_CN>

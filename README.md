# SWPlayer

封装AVPlayer 的硬解播放器, 支持hls流 以及mp4文件播放。
播放器UI可以自行定义

###支持pod导入

pod 'SWPlayer','~> 0.0.1'

如果发现pod search SWPlayer 搜索出来的不是最新版本，需要在终端执行pod setup命令更新本地spec缓存（可能需要几分钟），然后再搜索就可以了

###集成  

	SWPlayer *player = [[SWPlayer alloc] initWithFrame:self.bounds];  
	[player playWithUrl:[NSURL URLWithString:@"http://123.123.12.23.hls"]];
	
	
	
---  
####PS
播放器界面需要自己实现。接口已经全部暴露出来。
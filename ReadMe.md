# MTLivePhotoDemo文档

## 简介
1. 其中一个用于在iOS9.1以及以上设备拍摄livephoto，无设备限制。
2. 另一个用于在iOS10以上拍摄livephoto，调用系统的接口，限制机型为iphone6s以及更晚发布的手机。

## 详细介绍
1. 无设备限制的采用GPUImage（0.1.7）拍摄并添加滤镜，有添加实时滤镜、添加后期滤镜、预览界面长按预览、保存到相册功能
2. 调用iOS10接口的可以拍摄并保存到相册、附加长按预览功能

## 使用说明
* iOS版本要求：>= 9.1
* 要使用调用iOS接口的需要设备发布时间晚于iphone6s（包含）

## 参考资料
1.[GPUImage](https://github.com/BradLarson/GPUImage)

2.[AVCapturePhotoOutput](https://developer.apple.com/reference/avfoundation/avcapturephotooutput)

## 修改GPUImage说明
* 由于GPUImage的一些openbug会导致在debug模式下会奔溃，在release模式下正常，尝试了很多方案都没有修复，在这里对GPUImage的源码做了一些修改以保证在debug模式下能够正常运行

		1. 注释了GPUImageFramebuffer.m文件中第269行的assert，Tried to overrelease a framebuffer, did you forget to call -useNextFrameForImageCapture before using -imageFromCurrentFramebuffer?

		2. 注释了GPUImagePicture.m文件第74行的assert，Passed image must not be empty - it should be at least 1px tall and wide

		3. 注释了GPUImageFramebuffer.m文件第171行的assert，Error at CVOpenGLESTextureCacheCreateTextureFromImage


## 需要添加的依赖库

 * PhotoUI
 * Photos
 * Foundation
 * UIKit
 * CoreGraphics
 * CoreMedia
 * CoreVideo
 * OpenGLES
 * AVFoundation
 * QuartzCore
 * CoreImage

## iOS10LivePhoto使用说明

### git
![gif](https://github.com/supergithuber/LivePhoto-Demo/blob/master/iOS10.gif)

### iOS10livephoto使用准备

* 系统要求 > iOS10
* 机型要求无，但是在iphone6以及以下机型上运行会提示无法拍摄livephoto，要成功拍摄要求机型发布时间晚于iphone6s以及以后，即iphone6s，iphoneSE，iphone7以及以后
* 添加依赖PhotosUI，Photos，Foundation，CoreImage，AVFoundation，UIKit

### 使用方法

1. 将项目中的iOS10LivephotoDemo拖到你的项目中，拍摄界面是MTLivePhotoCaptureViewController是拍摄的界面。
2. 如果你已经有了自己的拍照界面controller，可以参考MTLivePhotoCaptureViewController的使用，在自己的controller中创建MTLivePhotoPreview，它的AVCaptureSession属性用于呈现拍摄的实时界面。
3. 开启步骤：

		* 在viewdidload中调用[MTLivePhotoCaptureSessionManager sharedManager]开启会话
		* 把会话的session的赋值给MTLivePhotoPreview的session用于展现实时拍摄画面
		* 通过MTLivePhotoCaptureSessionManager的authorize方法获得相机访问授权
		* 通过MTLivePhotoCaptureSessionManager的configureSession方法配置会话的输入输出
		* 在viewWillAppear中调用startSession开启会话，回调表示刚才的会话配置是否成功，你可以在回调中自己添加方法。例如我的demo中成功就添加KVC，失败就弹窗提示。
		* 不要忘了在viewWillDisappear中调用stopSession关闭会话并移除KVC监听
4. 点击拍照：在你的拍照按钮中调用MTLivePhotoCaptureSessionManager的captureWithVideoOrientation:completion:方法，回调个数表示正在拍摄的个数，你可以在回调中控制是否显示正在拍摄的label。
5. 切换前后摄像头：调用MTLivePhotoCaptureSessionManager的swapBackAndFrontCamera方法切换。
6. 关于通知：注册通知MTSuccessSaveLivePhoto（不要忘了释放哦），通知字典中的MTLivePhotoAsset可以拿到拍摄的livephoto的PHAsset。

## iOS9.1 livephoto使用说明

###gif
![gif](https://github.com/supergithuber/LivePhoto-Demo/blob/master/iOS9.1.gif)
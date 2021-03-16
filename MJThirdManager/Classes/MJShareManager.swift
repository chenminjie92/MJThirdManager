//
//  MJShareManager.swift
//  MJShareManager
//
//  Created by chenminjie on 2021/3/9.
//

import Foundation 
import WeiXinSDK_Swift

public protocol MJShareManagerProtocol: NSObjectProtocol {
    
    /// 分享结果
    func onShareComplete(_ resultStatus: MJShareManager.ResultStatus)
}


public class MJShareManager: NSObject {
    
    public enum Platform {
        /// 微信分享
        case weixin(scene: WXScene, type: WXMessageType)
    }
    
    public enum WXScene: Int {
        /// 会话
        case session = 0
        /// 朋友圈
        case timeline = 1
        /// 收藏
        case favorite = 2
    }
    
    public enum WXMessageType {
        /// 图片
        case image(imageData: Data)
        /// 链接
        case link(urlString: String, title: String?, description: String?, thumbData: Data?)
        /// 微信小程序
        case miniProgram(path: String, userName: String, title: String?, description: String?, thumbData: Data?)
    }
    
    public enum ResultStatus {
        /// 失败
        case fail
        /// 成功
        case success
        /// 取消
        case cancel
        /// 数据异常
        case unusual(message: String?)
        /// 未知
        case unknown
    }
    
    /// 代理组
    fileprivate var delegates: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    /// 单例
    public static let shared = MJShareManager()
    
    public override init() {
        super.init()
        MJThirdManager.shared.add(self)
    }
    
    deinit {
        MJThirdManager.shared.remove(self)
    }
}

extension MJShareManager {
    
    /// 分享
    /// - Parameter platform: 分享方式
    public func share(platform: Platform) {
        switch platform {
        case .weixin(let scene, let type):
            shareWeiXin(scene: scene, type: type)
        }
    }
    
    /// 添加代理
    /// - Parameter delgate: 代理
    public func add(_ delgate: MJShareManagerProtocol) {
        delegates.add(delgate)
    }
    
    /// 移除代理
    /// - Parameter delegate: 代理
    public func remove(_ delegate: MJShareManagerProtocol) {
        delegates.remove(delegate)
    }
}

extension MJShareManager {
    
    /// 微信分享验证
    func weiXinValidation(_ resp: SendMessageToWXResp) {
        var result: ResultStatus = .fail
        switch resp.errCode {
        case WXSuccess.rawValue:
            result = .success
        case WXErrCodeUserCancel.rawValue:
            result = .cancel
        default:
            break
        }

        invoke { (delegate) in
            delegate.onShareComplete(result)
        }
    }
    
    private func invoke(_ invocation: (MJShareManagerProtocol) -> Void) {
      for delegate in delegates.allObjects.reversed() {
        invocation(delegate as! MJShareManagerProtocol)
      }
    }
    
    private func compressImageUnder(bytes: Int, image: UIImage) -> Data? {
        var compress: CGFloat = 0.9
        var compressedData: Data? = image.jpegData(compressionQuality: compress)
        while compressedData?.count ?? 0 > bytes {
            compress -= 0.2
            if compress < 0 {
                compress = 0.0
            }
            compressedData = image.jpegData(compressionQuality: compress)
            if compress == 0.0 {
                break
            }
        }
        return compressedData
    }
}

extension MJShareManager {
    
    /// 微信分享
    private func shareWeiXin(scene: WXScene, type: WXMessageType) {
        let req = SendMessageToWXReq()
        req.bText = false
        switch type {
        case .image(let imageData):
            let wxImageObj = WXImageObject()
            if CGFloat(imageData.count) / 1_024.0 <= 25 * 1_024.0 {
                wxImageObj.imageData = imageData
            }
            else {
                if let image = UIImage(data: imageData), let _ = compressImageUnder(bytes: 25 * 1_024 * 1_024, image: image) {
                    wxImageObj.imageData = imageData
                } else {
                    invoke { (delegate) in
                        delegate.onShareComplete(.unusual(message: "图片资源异常"))
                    }
                    return
                }
            }
            let message = WXMediaMessage()
            message.mediaObject = wxImageObj
            req.message = message
           
        case .link(let urlString, let title, let description, let thumbData):
            let message = WXMediaMessage()
            message.title = title ?? ""
            message.description = description ?? ""
            guard !urlString.isEmpty else {
                invoke { (delegate) in
                    delegate.onShareComplete(.unusual(message: "链接不能为空"))
                }
                return
            }
            if let _thumbData = thumbData, let image = UIImage(data: _thumbData), let __thumbData = compressImageUnder(bytes: 32, image: image) {
                message.thumbData = __thumbData
            }
            let webpageObject = WXWebpageObject()
            webpageObject.webpageUrl = urlString
            message.mediaObject = webpageObject
            req.message = message
            
        case .miniProgram(let path, let userName,let title, let description, let thumbData):
            guard !path.isEmpty else {
                invoke { (delegate) in
                    delegate.onShareComplete(.unusual(message: "path不能为空"))
                }
                return
            }
            guard !userName.isEmpty else {
                invoke { (delegate) in
                    delegate.onShareComplete(.unusual(message: "userName不能为空"))
                }
                return
            }
            let program = WXMiniProgramObject()
            /// 兼容低版本的网页链接
            program.webpageUrl = ""
            /// 小程序的userName  /* 开发 gh_731c52da7f01 */  /* 测试 gh_36e3054c7d23 */
            program.userName = userName
            /// 小程序的页面路径
            program.path = path
            /// 128K
            if let _thumbData = thumbData, let image = UIImage(data: _thumbData), let __thumbData = compressImageUnder(bytes: 128, image: image) {
                /// 程序新版本的预览图二进制数据，6.5.9及以上版本微信客户端支持 128k
                program.hdImageData = __thumbData
            }
            /// 是否使用带shareTicket的分享
            program.withShareTicket = true
            /// 环境
            program.miniProgramType = MJThirdManager.shared.miniprogramType
            let message: WXMediaMessage = WXMediaMessage()
            message.title = title ?? " "
            message.description = description ?? " "
            message.thumbData = nil
            message.mediaObject = program
            req.message = message
        }
        
        req.scene = Int32(scene.rawValue)
        WXApi.send(req) {[weak self] (res) in
            if !res {
                self?.invoke { (delegate) in
                    delegate.onShareComplete(.unusual(message: "分享失败"))
                }
            }else{
                self?.invoke { (delegate) in
                    delegate.onShareComplete(.success)
                }
            }
        }
    }
}

extension MJShareManager: MJThirdManagerProtocol {
    func handleOpenUrl(url: URL) {
        
    }
    /// 收到一个来自微信的请求，第三方应用程序处理完后调用sendResp向微信发送结果
    func onReq(_ req: BaseReq) {
        
    }
    
    /// 发送一个sendReq后，收到微信的回应
    func onResp(_ resp: BaseResp) {
        if let result = resp as? SendMessageToWXResp{
            weiXinValidation(result)
        }
    }
}

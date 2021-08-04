//
//  MJThirdManager.swift
//  MJThirdManager
//
//  Created by chenminjie on 2021/3/10.
//

import Foundation
import WeiXinSDK_Swift
import AlipaySDK_NoUTDID_Swift

protocol MJThirdManagerProtocol: NSObjectProtocol {
    
    /// 收到一个来自微信的请求，第三方应用程序处理完后调用sendResp向微信发送结果
    func onReq(_ req: BaseReq)
    
    /// 发送一个sendReq后，收到微信的回应
    func onResp(_ resp: BaseResp)
    
    /// 打开网页
    func handleOpenUrl(url:URL)
}

public class MJThirdManager: NSObject {
    
    public enum Platform {
        /// 微信 wxAppID： id ，wxUniversalLink：linkUrl， programType：小程序环境
        case weiXin(wxAppID: String, wxUniversalLink: String, programType: WXMiniProgramType)
        /// app自定义名字
        case zhifubao(scheme: String)
    }
    /// 是否安装微信
    public static var isWXAppInstalled: Bool {
        return WXApi.isWXAppInstalled() && WXApi.isWXAppSupport()
    }
    /// 单例
    public static let shared = MJThirdManager()
    
    /// 微信小程序环境
    var miniprogramType: WXMiniProgramType = .release
    /// 平台scheme
    var scheme: String?
    // 代理组
    var delegates: NSHashTable<AnyObject> = NSHashTable.weakObjects()
}

extension MJThirdManager {
    /// 添加代理
    /// - Parameter delgate: 代理
    func add(_ delgate: MJThirdManagerProtocol) {
        delegates.add(delgate)
    }
    
    /// 移除代理
    /// - Parameter delegate: 代理
    func remove(_ delegate: MJThirdManagerProtocol) {
        delegates.remove(delegate)
    }
    
    fileprivate func invoke(_ invocation: (MJThirdManagerProtocol) -> Void) {
      for delegate in delegates.allObjects.reversed() {
        invocation(delegate as! MJThirdManagerProtocol)
      }
    }
}
extension MJThirdManager {
    
    ///  需要在 application:openURL:sourceApplication:annotation:或者application:handleOpenURL中调用。
    /// - Parameter url: 第三方应用时传递过来的URL
    /// - Returns: 成功返回YES，失败返回NO
    @discardableResult
    public static func handleOpenUrl(url:URL) -> Bool {
        MJThirdManager.shared.invoke { (delegate) in
            delegate.handleOpenUrl(url: url)
        }
        if url.host == "safepay" {
            return true
        }
        return WXApi.handleOpen(url, delegate: MJThirdManager.shared)
    }
        
    ///处理微信通过 通用链接 启动App时传递的数据
    @discardableResult
    public static func handleOpenUniversalLink(activity: NSUserActivity) -> Bool {
        return WXApi.handleOpenUniversalLink(activity, delegate: MJThirdManager.shared)
    }
    
    /// 批量注册
    /// - Parameter platforms: 注册的平台
    public static func registered(platforms: [Platform]) {
        for platform in platforms {
            switch platform {
            case .weiXin(let wxAppID, let wxUniversalLink, let programType):
                MJThirdManager.registeredWaChat(wxAppID: wxAppID, wxUniversalLink: wxUniversalLink, programType: programType)
            case .zhifubao(let scheme):
                MJThirdManager.shared.scheme = scheme
            }
        }
    }
}
extension MJThirdManager {
        
    /// 注册微信
    @discardableResult
    fileprivate static func registeredWaChat(wxAppID: String, wxUniversalLink: String, programType: WXMiniProgramType) -> Bool {
        MJThirdManager.shared.miniprogramType = programType
        return WXApi.registerApp(wxAppID, universalLink: wxUniversalLink)
    }
}

extension MJThirdManager: WXApiDelegate {
    
    public func onReq(_ req: BaseReq) {
        invoke { (delegate) in
            delegate.onReq(req)
        }
    }
    
    public func onResp(_ resp: BaseResp) {
        invoke { (delegate) in
            delegate.onResp(resp)
        }
    }
}


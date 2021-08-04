//
//  MJLoginManager.swift
//  MJExtensions
//
//  Created by chenminjie on 2021/3/10.
//

import Foundation
import WeiXinSDK_Swift
import AuthenticationServices

public protocol MJLoginManagerProtocol: NSObjectProtocol {
    
    /// 登录结果
    func onLoginComplete(_ resultStatus: MJLoginManager.ResultStatus, platform: MJLoginManager.Platform?)
}

public class MJLoginManager: NSObject {
    
    public enum Platform {
        /// 微信登录
        case weixin(scope: String, state: String)
        /// 苹果登录
        case apple
    }
    
    public enum ResultStatus {
        /// 失败
        case fail
        /// 成功
        case success(token: String?, userId: String?, nikeName: String?)
        /// 取消
        case cancel
        /// 数据异常
        case unusual(message: String?)
        /// 未知
        case unknown
    }
    var platform: Platform?
    
    /// 代理组
    fileprivate var delegates: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    /// 单例
    public static let shared = MJLoginManager()
    
    public override init() {
        super.init()
        MJThirdManager.shared.add(self)
    }
    
    deinit {
        MJThirdManager.shared.remove(self)
    }
}

extension MJLoginManager {
    
    /// 登录
    /// - Parameter platform: 登录的平台
    public func login(platform: Platform) {
        self.platform = platform
        switch platform {
        case .weixin(let scope, let state):
            weiXinLogin(scope: scope, state: state)
        case .apple:
            handleAuthorizationAppleIDButtonPress()
        }
    }
    
    /// 添加代理
    /// - Parameter delgate: 代理
    public func add(_ delgate: MJLoginManagerProtocol) {
        delegates.add(delgate)
    }
    
    /// 移除代理
    /// - Parameter delegate: 代理
    public func remove(_ delegate: MJLoginManagerProtocol) {
        delegates.remove(delegate)
    }
}

extension MJLoginManager {
    
    private func invoke(_ invocation: (MJLoginManagerProtocol) -> Void) {
      for delegate in delegates.allObjects.reversed() {
        invocation(delegate as! MJLoginManagerProtocol)
      }
    }
}
extension MJLoginManager {
    
    /// 微信登录
    private func weiXinLogin(scope: String, state: String) {
        guard !scope.isEmpty else {
            return
        }
        guard !state.isEmpty else {
            return
        }
        let req = SendAuthReq()
        req.scope = scope
        req.state = state
        WXApi.send(req)
    }
    
    /// 微信登录验证
    private func weiXinValidation(_ resp: SendAuthResp) {
        var status: ResultStatus = .fail
        switch resp.errCode {
        case WXSuccess.rawValue:
            status = .success(token: resp.code ?? "", userId: nil, nikeName: nil)
        case WXErrCodeUserCancel.rawValue:
            status = .cancel
        default:
            status = .fail
        }
        invoke { (delegate) in
            delegate.onLoginComplete(status, platform: self.platform)
        }
        self.platform = nil
    }
    
    /// 发起苹果登录
    private func handleAuthorizationAppleIDButtonPress() {
        if #available(iOS 13.0, *) {
            // // 基于用户的Apple ID授权用户，生成用户授权请求的一种机制
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            // 创建新的AppleID 授权请求
            let appleIDRequest = appleIDProvider.createRequest()
            // 在用户授权期间请求的联系信息
            appleIDRequest.requestedScopes = [.fullName, .email]
            // 由ASAuthorizationAppleIDProvider创建的授权请求 管理授权请求的控制器
            let authorizationController = ASAuthorizationController.init(authorizationRequests: [appleIDRequest])
            // 设置授权控制器通知授权请求的成功与失败的代理
            authorizationController.delegate = self
            // 设置提供 展示上下文的代理，在这个上下文中 系统可以展示授权界面给用户
            authorizationController.presentationContextProvider = self
            // 在控制器初始化期间启动授权流
            authorizationController.performRequests()
        }
    }
}

extension MJLoginManager: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    @available(iOS 13.0, *)
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.last ?? ASPresentationAnchor()
    }
    
    // 授权成功地回调
    @available(iOS 13.0, *)
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    
        if let _appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential, let _identityToken = _appleIDCredential.identityToken {
            
            let identityTokenStr = String.init(data: _identityToken, encoding: .utf8)
            let userName = (_appleIDCredential.fullName?.familyName ?? "") +  (_appleIDCredential.fullName?.givenName ?? "")
            var name: String? = nil
            if userName.count > 0 {
                name = userName
            }
            invoke { (delegate) in
                delegate.onLoginComplete(.success(token: identityTokenStr, userId: _appleIDCredential.user, nikeName: name), platform:self.platform)
            }
        }
        else{
            // "授权信息不符合"
        }
        self.platform = nil
    }
    
    // 授权失败的回调
    @available(iOS 13.0, *)
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {

        var status: ResultStatus = .fail
        switch error {
        case ASAuthorizationError.canceled:
            status = .cancel
        case ASAuthorizationError.failed:
            status = .fail
        case ASAuthorizationError.invalidResponse:
            status = .unusual(message: "授权请求响应无效")
        case ASAuthorizationError.notHandled:
            status = .unusual(message: "未能处理授权请求")
        case ASAuthorizationError.unknown:
            status = .unknown
        default:
            break;
        }
        invoke { (delegate) in
            delegate.onLoginComplete(status, platform: self.platform)
        }
        self.platform = nil
    }
}

extension MJLoginManager: MJThirdManagerProtocol {
    
    /// 收到一个来自微信的请求，第三方应用程序处理完后调用sendResp向微信发送结果
    func onReq(_ req: BaseReq) {
        
    }
    
    /// 发送一个sendReq后，收到微信的回应
    func onResp(_ resp: BaseResp) {
        if let result = resp as? SendAuthResp{
            weiXinValidation(result)
        }
    }
    
    /// 打开网页
    func handleOpenUrl(url:URL) {
        
    }
}



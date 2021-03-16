//
//  MJPayManager.swift
//  MJExtensions
//
//  Created by chenminjie on 2021/3/4.
//

import Foundation
import AlipaySDK_NoUTDID_Swift
import WeiXinSDK_Swift

public protocol MJPayManagerProtocol: AnyObject {
    
    /// 支付结果
    /// - Parameters:
    ///   - resultStatus: 支付结果状态
    ///   - platform: 支付的平台
    func onPayComplete(resultStatus: MJPayManager.ResultStatus, platform: MJPayManager.Platform?)
}

public class MJPayManager: NSObject {
    
    public enum Platform {
        /// 微信支付  partnerId:商家向财付通申请的商家id,  prepayId:预支付订单,  nonceStr:随机串，防重发 ,  timeStamp:时间戳，防重发  sign: 商家根据微信开放平台文档对数据做的签名,   orderNo: 后期回调像服务器查询支付结果
        case weixin(partnerId: String, prepayId: String, nonceStr: String, timeStamp: String, sign: String, orderNo: String?)
        /// 支付宝支付。orderCode：支付参数， orderNo: 后期回调像服务器查询支付结果
        case zhifubao(orderCode: String, orderNo: String? = nil)
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

    /// 平台自定义名字
    var scheme: String? {
        return MJThirdManager.shared.scheme
    }
    /// 当前支付的平台
    private(set) var platform: Platform?
    /// 代理组
    fileprivate var delegates: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    /// 单例
    public static let shared = MJPayManager()
    
    public override init() {
        super.init()
        MJThirdManager.shared.add(self)
    }
    
    deinit {
        MJThirdManager.shared.remove(self)
    }
}

extension MJPayManager {
    
    /// 支付宝验证
    func zhiFuBaoValidation(_ url: URL) {
        if url.host == "safepay" {
            AlipaySDK.defaultService()?.processAuthResult(url, standbyCallback: {[unowned self] (resultDic) in
                var status: ResultStatus = .unknown
                /// h5支付回调
                let resultStatus = resultDic?["resultStatus"] as? String
                
                if let statusCode = resultStatus {
                    if Int(statusCode) == 9000 {
                        status = .success
                    } else if Int(statusCode) == 6001  {
                        status = .cancel
                    }
                    else {
                        status = .fail
                    }
                }
                invoke { (delegate) in
                    delegate.onPayComplete(resultStatus: status, platform: platform)
                }
                
            })
        }
    }
    
    
    /// 微信验证
    func weiXinValidation(_ resp:PayResp) {
        var status: ResultStatus = .fail
        switch resp.errCode {
        case WXSuccess.rawValue:
            status = .success
        case WXErrCodeUserCancel.rawValue:
            status = .cancel
        default:
            status = .fail
        }
        invoke { (delegate) in
            delegate.onPayComplete(resultStatus: status, platform: platform)
        }
    }
    
    /// 支付
    /// - Parameter platform: 支付平台
    public func pay(for platform: Platform) {
        self.platform = platform
        switch platform {
        case .weixin(let partnerId, let prepayId, let nonceStr, let timeStamp, let sign, _):
            let req = PayReq()
            req.partnerId = partnerId
            req.prepayId = prepayId
            req.nonceStr = nonceStr
            req.timeStamp = UInt32(timeStamp) ?? 0
            req.package = "Sign=WXPay"
            req.sign = sign
            WXApi.send(req)
        case .zhifubao(let orderCode, _):
            guard let _scheme = scheme else {
                invoke { (delegate) in
                    delegate.onPayComplete(resultStatus: .unusual(message: "未配置scheme"), platform: platform)
                }
                return
            }
            AlipaySDK.defaultService()?.payOrder(orderCode, fromScheme: _scheme, callback: {[unowned self] (resultDic) in
                var status: ResultStatus = .unknown
                /// h5支付回调
                let resultStatus = resultDic?["resultStatus"] as? String
                
                if let statusCode = resultStatus {
                    if Int(statusCode) == 9000 {
                        status = .success
                    } else if Int(statusCode) == 6001  {
                        status = .cancel
                    }
                    else {
                        status = .fail
                    }
                }
                invoke { (delegate) in
                    delegate.onPayComplete(resultStatus: status, platform: platform)
                }
                
            })
        }
    }
    /// 添加代理
    /// - Parameter delgate: 代理
    public func add(_ delgate: MJPayManagerProtocol) {
        delegates.add(delgate)
    }
    
    /// 移除代理
    /// - Parameter delegate: 代理
    public func remove(_ delegate: MJPayManagerProtocol) {
        delegates.remove(delegate)
    }
}

extension MJPayManager {
    
    fileprivate func invoke(_ invocation: (MJPayManagerProtocol) -> Void) {
      for delegate in delegates.allObjects.reversed() {
        invocation(delegate as! MJPayManagerProtocol)
      }
    }
}

extension MJPayManager: MJThirdManagerProtocol {
    
    /// 收到一个来自微信的请求，第三方应用程序处理完后调用sendResp向微信发送结果
    func onReq(_ req: BaseReq) {
        
    }
    
    /// 发送一个sendReq后，收到微信的回应
    func onResp(_ resp: BaseResp) {
        if let result = resp as? PayResp{
            weiXinValidation(result)
        }
    }
    
    /// 打开网页
    func handleOpenUrl(url:URL) {
        if url.host == "safepay" {
            zhiFuBaoValidation(url)
        }
    }
}

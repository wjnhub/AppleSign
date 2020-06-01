//
//  ViewController.swift
//  AppleSign
//
//  Created by wjn on 2020/6/1.
//  Copyright © 2020 wjn. All rights reserved.
//

import UIKit
import AuthenticationServices

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setupProviderLoginView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        performExistingAccountSetupFlows()
    }
    
    func performExistingAccountSetupFlows() {
        // 为Apple ID和密码提供者准备请求。
        let requests = [ASAuthorizationAppleIDProvider().createRequest(),
                        ASAuthorizationPasswordProvider().createRequest()]
        
        // 管理授权请求控制器
        let authorizationController = ASAuthorizationController(authorizationRequests: requests)
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    // 添加Apple登录按钮
    func setupProviderLoginView() {
        let appleButton = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        appleButton.addTarget(self, action: #selector(handleAuthorizationAppleIDButtonPress), for: .touchUpInside)
        appleButton.frame = CGRect(x: 100, y: 200, width: 200, height: 50)
        appleButton.cornerRadius = 10
        self.view.addSubview(appleButton)
    }

    // appleid请求
    @objc
    func handleAuthorizationAppleIDButtonPress() {
        // 基于用户的Apple ID授权用户，生成用户授权请求机制
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        // 创建Apple ID授权请求
        let request = appleIDProvider.createRequest()
        // 请求的Apple用户信息类型
        request.requestedScopes = [.fullName, .email]
        
        // 管理授权请求控制器
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        // 请求回调 成功/失败的代理
        authorizationController.delegate = self
        //显示上下文的代理，系统可以在上下文中展示授权页面
        authorizationController.presentationContextProvider = self
        // 控制器初始化期间启动授权
        authorizationController.performRequests()
    }

}

extension ViewController: ASAuthorizationControllerDelegate {
    // 授权成功回调
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            // 用户的详细信息
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            let authorizationCode = appleIDCredential.authorizationCode!
            let identityToken = appleIDCredential.identityToken!
            
            // 将userIdentifier保存到钥匙串中
            self.saveUserInKeychain(userIdentifier)
            print("userIdentifier: \(userIdentifier) \n fullName: \(String(describing: fullName)) \n email: \(String(describing: email))  authorizationCode: \(String(describing: String(data: authorizationCode, encoding: String.Encoding.utf8)))  identityToken: \(String(describing: String(data: identityToken, encoding: String.Encoding.utf8))) \(appleIDCredential)")

        case let passwordCredential as ASPasswordCredential:
        
            // 密码凭证的用户唯一表示
            let username = passwordCredential.user
            // 密码凭证的密码
            let password = passwordCredential.password
            
            print("username: \(username)  \n password: \(password)")
            DispatchQueue.main.async {
                self.showPasswordCredentialAlert(username: username, password: password)
            }
        default:
            break
        }
    }
    // 授权失败回调
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("授权错误: \(error)")
        var errorText = ""
        if let authError = error as? ASAuthorizationError {
            let code = authError.code
            switch code {
            case .canceled:
                errorText = "用户取消了授权请求"
            case .failed:
                errorText = "授权请求失败"
            case .invalidResponse:
                errorText = "授权请求响应无效"
            case .notHandled:
                errorText = "未能处理授权请求"
            case .unknown:
                errorText = "授权请求失败, 未知的错误原因"
            default:
                errorText = "其他未知的错误原因"
            }
        }
        print(errorText)
    }
    
    
    private func showPasswordCredentialAlert(username: String, password: String) {
        let message = "The app has received your selected credential from the keychain. \n\n Username: \(username)\n Password: \(password)"
        let alertController = UIAlertController(title: "Keychain Credential Received",
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func saveUserInKeychain(_ userIdentifier: String) {
        do {
            try KeychainItem(service: "com.mainone.AppleSign", account: "userIdentifier").saveItem(userIdentifier)
        } catch {
            print("Unable to save userIdentifier to keychain.")
        }
    }
}

extension ViewController: ASAuthorizationControllerPresentationContextProviding {
    // 代理应该在哪个window 展示内容给用户
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}

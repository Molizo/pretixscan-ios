//
//  SceneDelegate.swift
//  pretixSCAN
//
//  Created by Konstantin Kostov on 26/10/2023.
//  Copyright © 2023 rami.io. All rights reserved.
//

import UIKit

struct SetupDeepLink {
    let url: URL
    let token: String

    init?(incomingURL: URL) {
        guard incomingURL.scheme?.lowercased() == "pretixscan" else { return nil }
        guard incomingURL.host?.lowercased() == "setup" else { return nil }
        guard let components = URLComponents(url: incomingURL, resolvingAgainstBaseURL: false) else { return nil }
        guard let urlString = components.queryItems?.first(where: { $0.name == "url" })?.value else { return nil }
        guard let url = URL(string: urlString) else { return nil }
        guard let token = components.queryItems?.first(where: { $0.name == "token" })?.value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !token.isEmpty else { return nil }

        self.url = url
        self.token = token
    }
}

extension Notification.Name {
    static let setupDeepLinkReceived = Notification.Name("SetupDeepLinkReceived")
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        UIButton.appearance().tintColor = PXColor.buttons
        UIProgressView.appearance().tintColor = PXColor.buttons
        UIActivityIndicatorView.appearance().tintColor = PXColor.buttons
        UIView.appearance().tintColor = PXColor.buttons

        if let url = connectionOptions.urlContexts.first?.url {
            handleSetupLink(url: url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handleSetupLink(url: url)
    }

    private func handleSetupLink(url: URL) {
        guard url.scheme?.lowercased() == "pretixscan" else { return }
        guard url.host?.lowercased() == "setup" else { return }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

        guard let setupLink = SetupDeepLink(incomingURL: url) else {
            presentSetupLinkAlert(message: Localization.ConnectDeviceViewController.SetupLinkInvalid)
            return
        }

        guard appDelegate.configStore?.isDeviceInitialized != true else {
            presentSetupLinkAlert(message: Localization.ConnectDeviceViewController.SetupLinkAlreadyConfigured)
            return
        }

        appDelegate.pendingSetupLink = setupLink

        DispatchQueue.main.async {
            if let validateController = self.topViewController(from: self.window?.rootViewController) as? ValidateTicketViewController {
                validateController.checkFirstRunActions()
            }
            NotificationCenter.default.post(name: .setupDeepLinkReceived, object: nil)
        }
    }

    private func presentSetupLinkAlert(message: String) {
        DispatchQueue.main.async {
            guard let viewController = self.topViewController(from: self.window?.rootViewController) else { return }

            let alert = UIAlertController(
                title: Localization.Errors.Error,
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: Localization.Errors.Confirm, style: .default))
            viewController.present(alert, animated: true)
        }
    }

    private func topViewController(from viewController: UIViewController?) -> UIViewController? {
        if let navigationController = viewController as? UINavigationController {
            return topViewController(from: navigationController.visibleViewController)
        }

        if let tabBarController = viewController as? UITabBarController {
            return topViewController(from: tabBarController.selectedViewController)
        }

        if let presentedViewController = viewController?.presentedViewController {
            return topViewController(from: presentedViewController)
        }

        return viewController
    }
}

//
//  TopViewControllerTests.swift
//  WishieTests
//

import Testing
import UIKit
@testable import Wishie

struct TopViewControllerTests {
    @Test func returnsBaseWhenNoChildrenOrPresentation() {
        let vc = UIViewController()
        #expect(UIApplication.topViewController(base: vc) === vc)
    }

    @Test func returnsVisibleViewControllerForNavigationController() {
        let root = UIViewController()
        let pushed = UIViewController()
        let nav = UINavigationController(rootViewController: root)
        nav.viewControllers = [root, pushed]
        #expect(UIApplication.topViewController(base: nav) === pushed)
    }

    @Test func returnsSelectedViewControllerForTabBarController() {
        let tabA = UIViewController()
        let tabB = UIViewController()
        let tabBar = UITabBarController()
        tabBar.viewControllers = [tabA, tabB]
        tabBar.selectedViewController = tabB
        #expect(UIApplication.topViewController(base: tabBar) === tabB)
    }

    @Test func recursesThroughNestedNavigationInsideTabBar() {
        let pushed = UIViewController()
        let nav = UINavigationController(rootViewController: UIViewController())
        nav.viewControllers = [UIViewController(), pushed]
        let tabBar = UITabBarController()
        tabBar.viewControllers = [nav]
        tabBar.selectedViewController = nav
        #expect(UIApplication.topViewController(base: tabBar) === pushed)
    }

    @Test func returnsNilForNilBase() {
        #expect(UIApplication.topViewController(base: nil) == nil)
    }
}

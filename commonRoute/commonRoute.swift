//
//  commonRoute.swift
//  commonRoute
//
//  Created by Two_Lights on 2018/6/11.
//  Copyright © 2018年 BSH. All rights reserved.
//

import UIKit

@objc open class commonRoute: NSObject {
    public var _cachedTargetDict: NSMutableDictionary? = NSMutableDictionary()//缓存的target
    
    /** 单例 */
    fileprivate static let _theInstance: commonRoute = commonRoute()
    
    /**
     * @函数说明    单例函数
     * @返回数据    单例
     */
    @objc public static func sharedInstance() -> commonRoute {
        return _theInstance;
    }
    
    /** 构造(重载init为私有，避免外部对象通过访问init方法创建其他实例) */
    private override init() {
        
    }
    
    /** 析构 */
    deinit {
        print("已销毁: \(String.init(describing: type(of: self)))")
        
        /// 释放属性
        self._cachedTargetDict = nil
    }
    
    /**
     * @函数说明    远程App调用入口
     * @输入参数    url: 需要传入的url类型
     * @输入参数    completionHandler: 完成回调,参数字典中"result"为实际执行方法的返回值
     * @返回数据    实际执行方法的返回值
     */
    @objc open func performActionWithUrl(url:NSURL, completionHandler:(NSDictionary) -> Void) -> Any?{
        /** 获取参数(字典) */
        let params = NSMutableDictionary()
        let queryString = url.query
        for param: String in (queryString?.components(separatedBy: "&"))! {
            let elts = param.components(separatedBy: "=")
            if elts.count < 2 {
                continue
            } else {
                params[elts.first] = elts.last
            }
        }
        
        /** 判断是否远程App调用(actionName是以native开头) */
        let pathString = url.path
        let actionName = pathString?.replacingOccurrences(of: "/", with: "")
        if (actionName?.hasPrefix("native"))! {
            return false
        }
        
        /** 本地组件调用入口 */
        let targetName = url.host
        let result = commonRoute._theInstance.performTarget(targetName: targetName!, actionName: actionName!, params: params, isCacheTarget: false)
        /** 回调 */
        if result != nil {
            completionHandler(["result": result!])
        } else {
            completionHandler(["result": ""])
        }
        
        return result
    }
    
    // MARK: - 本地组件调用入口
    fileprivate func performTarget(targetName: String,actionName: String, params: NSDictionary, isCacheTarget: Bool) -> Any? {
        
        /** 生成target的key(类的名称) */
        let targetKey = "\(targetName)"
        
        /** 从缓存中读取target的value */
        var target = commonRoute._theInstance._cachedTargetDict?[targetKey]
        
        /** 缓存中不存在，则创建target */
        if target == nil {
            let targetClass: AnyClass? = NSClassFromString(targetKey)
            if targetClass != nil {
                let cls = targetClass as! NSObject.Type
                target = cls.init()
            } else {
                return nil;
            }
        }
        
        /** 判断target是否存在 */
        if target == nil {
            return nil;
        }
        
        /** 添加target到缓存 */
        if isCacheTarget == true {
            commonRoute._theInstance._cachedTargetDict?[targetKey] = target
        }
        
        /** 生成action的key(方法的名称) */
        let actionKey = "\(actionName)"
        
        /** 生成action(方法) */
        let action: Selector = NSSelectorFromString(actionKey)
        
        /** 判断target(类)中是否存在action方法 */
        let cls = target as! NSObject.Type
        if cls.responds(to: action) {
            return cls.perform(action, with: params)
        } else {
            return nil
        }
    }
    
    // MARK: - 释放cacheTarget
    fileprivate func releaseCachedTarget(withTargetName targetName: String?) {
        let targetKey = "\(String(describing: targetName))"
        commonRoute._theInstance._cachedTargetDict?.removeObject(forKey: targetKey)
    }
    
    
}

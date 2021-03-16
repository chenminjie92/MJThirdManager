//
//  MulticastDelegate.swift
//  MJLoginManager
//
//  Created by chenminjie on 2021/3/10.
//

import Foundation

/// MulticastDelegate` 可以轻松地为给定的协议或类创建一个多重代理。
class MulticastDelegate<T>: NSObject {
    
    /**
     *  用来存储delegate的数组
     */
    fileprivate var delegates = [MulticastDelegateWeak]()
    
    /**
     *  用这个属性来判断delegates是否为空
     *
     *  如果数组delegates中一个元素都没有返回true
     */
    var isEmpty: Bool {
        
        return delegates.count == 0
    }
    
    /**
     *  这个方法用来向delegates中添加新的delegate
     */
    func add(_ delegate: T) {
        
        guard !self.contains(delegate) else {
            return
        }
        
        delegates.append(MulticastDelegateWeak(value: delegate as AnyObject))
    }
    
    /**
     *  这个方法用来删除delegates中某个delegate
     */
    func remove(_ delegate: T) {
        
        let weak = MulticastDelegateWeak(value: delegate as AnyObject)
        if let index = delegates.firstIndex(of: weak) {
            delegates.remove(at: index)
        }
    }
    
    /**
     *  这个方法用来触发代理方法
     */
    func invoke(_ invocation: @escaping (T) -> Void) {
        
        clearNil()
        delegates.forEach({
            if let delegate = $0.value as? T {
                invocation(delegate)
            }
        })
    }
    
    /**
     *  这个方法用来判断delegates中是否已经存在某个delegate
     */
    private func contains(_ delegate: T) -> Bool {
        
        return delegates.contains(MulticastDelegateWeak(value: delegate as AnyObject))
    }
    
    /**
     *  这个方法用来移除delegates中无效的delegate
     */
    private func clearNil() {
        
        delegates = delegates.filter { $0.value != nil }
    }
    
}

/**
 *  自定义操作符实现delegate的添加，同add
 *
 *  - 参数 left:   The multicast delegate
 *  - 参数 right:  The delegate to be added
 */
func +=<T>(left: MulticastDelegate<T>, right: T) {
    
    left.add(right)
}

/**
 *  自定义操作符实现delegate的删除，同remove
 *
 *  - 参数 left:   The multicast delegate
 *  - 参数 right:  The delegate to be removed
 */
func -=<T>(left: MulticastDelegate<T>, right: T) {
    
    left.remove(right)
}

/**
 *  自定义类型添加Sequence，需要添加返回迭代器的方法 -> makeIterator()，实现for循环功能
 */
extension MulticastDelegate: Sequence {
    func makeIterator() -> AnyIterator<T> {
        clearNil()
        
        var iterator = delegates.makeIterator()
        
        return AnyIterator {
            while let next = iterator.next() {
                if let delegate = next.value {
                    return delegate as? T
                }
            }
            return nil
        }
    }
}

class MulticastDelegateWeak: Equatable {
    
    weak var value: AnyObject?
    
    init(value: AnyObject) {
        self.value = value
    }
    
    static func ==(lhs: MulticastDelegateWeak, rhs: MulticastDelegateWeak) -> Bool {
        return lhs.value === rhs.value
    }
}

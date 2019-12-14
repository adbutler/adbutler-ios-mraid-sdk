//
//  AsynchronousOperation.swift
//  AdButler
//
//  Created by Ben Scheirman on 7/1/15.
//  Modified by Ryuichi Saito on 11/11/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

import Foundation

class AsynchronousOperation: Operation {
    override var isAsynchronous: Bool {
        return true
    }
    
    private var _executing = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }

    override var isExecuting: Bool {
        return _executing
    }

    private var _finished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }

        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }

    override var isFinished: Bool {
        return _finished
    }
    
    override func start() {
        _executing = true
        main()
    }
    
    func finish() {
        _executing = false
        _finished = true
    }
}

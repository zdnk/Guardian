//
//  Guardian.swift
//  Guardian
//
//  Created by Topic, Zdenek on 30/10/2017.
//  Copyright © 2017 Zdenek Topic. All rights reserved.
//

import Foundation
import LocalAuthentication

// MARK: - Public API
open class Guardian {

    public enum BiometryType {
        case none
        case faceId
        case touchId
    }
    
    public enum AuthenticationType {
        case biometryOrPasscode
        case biometry
    }
    
    public enum Error: Swift.Error {
        case appCancel
        case systemCancel
        case cancel
        case biometryNotEnrolled
        case biometryLockout
        case biometryNotAvailable
        case passcodeNotSet
        case fallback
        case failed
        case other(Swift.Error)
    }
    
    public enum FallbackTitle {
        case hide
        case custom(String)
        case enterPassword
    }
    
    public enum CancelTitle {
        case cancel
        case custom(String)
    }
    
    public enum AuthenticationResult {
        case success
        case failure(Error)
    }
    
    public typealias AuthenticationResultClosure = (AuthenticationResult) -> Void
    
    /// Device support for TouchID or FaceID
    /// - returns: `true` if the device supports FaceID or TouchID, otherwise `false`
    open var supportsBiometric: Bool {
        var error: NSError?
        if context().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return  error == nil
        }
        
        return false
    }
    
    /// Check if the device supports FaceID
    /// - returns: `true` if the device supports FaceID, otherwise `false`
    open var supportsFaceId: Bool {
        return biometryType == .faceId
    }
    
    /// Check if the device supports TouchID
    /// - returns: `true` if the device supports TouchID, otherwise `false`
    open var supportsTouchId: Bool {
        return biometryType == .touchId
    }
    
    /// Type of the biometric support in the device
    /// - returns: `BiometryType.none` for no support of biometric identity verification, `BiometryType.faceId` for FaceID, `BiometryType.touchId` for TouchID
    open var biometryType: BiometryType {
        if #available(iOS 11.0 , *) {
            return BiometryType(laBiometryType: context().biometryType)
        }

        var error: NSError?
        if context().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) && error == nil {
            return .touchId
        }
        
        return .none
    }
    
    open var defaultReason: String?
    open var defaultFallbackTitle: FallbackTitle = .enterPassword
    open var defaultCancelTitle: CancelTitle = .cancel
    
    public init() {}
    
    open func authenticate(
        using type: AuthenticationType,
        reason: String? = nil,
        fallbackTitle fallback: FallbackTitle? = nil,
        cancelTitle cancel: CancelTitle? = nil,
        _ callback: @escaping AuthenticationResultClosure
    ) {
        let context = self.context()
        context.localizedFallbackTitle = fallback?.string ?? defaultFallbackTitle.string
        context.localizedCancelTitle = cancel?.string ?? defaultCancelTitle.string
        
        let finalReason = self.reason(from: reason)
        
        context.evaluatePolicy(type.policy, localizedReason: finalReason) { (success, error) in
            if let error = error {
                if let laError = error as? LAError {
                    callback(.failure(Error(laError: laError)))
                } else {
                    callback(.failure(.other(error)))
                }
            } else {
                callback(.success)
            }
        }
    }
    
}

// MARK: - Private helpers
extension Guardian {
    
    internal func context() -> LAContext {
        return LAContext()
    }
    
    internal func reason(from reason: String?) -> String {
        var result = reason
        if result == nil || result?.isEmpty == true {
            result = defaultReason
        }
        
        if result == nil || result?.isEmpty == true {
            fatalError("You must provide at least one of the following: Guardian.defaultReason or reason in the  `Guardian.authenticate` method.")
        }
        
        return result!
    }
    
}

extension Guardian.FallbackTitle {
    
    internal var string: String? {
        switch self {
        case .hide:
            return ""
        case .enterPassword:
            return nil
        case .custom(let value):
            return value
        }
    }
    
}

extension Guardian.CancelTitle {
    
    internal var string: String? {
        switch self {
        case .custom(let value):
            return value
        case .cancel:
            return nil
        }
    }
    
}

extension Guardian.AuthenticationType {
    
    internal var policy: LAPolicy {
        switch self {
        case .biometry:
            return .deviceOwnerAuthenticationWithBiometrics
        case .biometryOrPasscode:
            return .deviceOwnerAuthentication
        }
    }
    
}

extension Guardian.AuthenticationResult {
    
    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        default:
            return false
        }
    }
    
}

extension Guardian.BiometryType {
    
    @available(iOS 11.0, *)
    internal init(laBiometryType: LABiometryType) {
        switch laBiometryType {
        case .none:
            self = .none
        case .typeFaceID:
            self = .faceId
        case .typeTouchID:
            self = .touchId
        }
    }
    
}

extension Guardian.Error {
    
    internal init(laError: LAError) {
        if laError.code == LAError.appCancel {
            self = .appCancel
        } else if laError.code == LAError.userFallback {
            self = .fallback
        } else if laError.code == LAError.systemCancel {
            self = .systemCancel
        } else if laError.code == LAError.authenticationFailed {
            self = .failed
        } else if laError.code == LAError.passcodeNotSet {
            self = .passcodeNotSet
        } else if #available(iOS 11.0, *) {
            if laError.code == LAError.biometryNotEnrolled {
                self = .biometryNotEnrolled
            } else if laError.code == LAError.biometryLockout {
                self = .biometryLockout
            } else if laError.code == LAError.biometryNotAvailable {
                self = .biometryNotAvailable
            } else {
                self = .other(laError)
            }
        } else {
            if laError.code == LAError.touchIDNotEnrolled {
                self = .biometryNotEnrolled
            } else if laError.code == LAError.touchIDLockout {
                self = .biometryLockout
            } else if laError.code == LAError.touchIDNotAvailable {
                self = .biometryNotAvailable
            } else {
                self = .other(laError)
            }
        }
    }
    
    public var isCancel: Bool {
        switch self {
        case .appCancel, .systemCancel, .cancel:
            return true
        default:
            return false
        }
    }
    
}

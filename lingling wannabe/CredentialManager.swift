//
//  CredentialManager.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 12/22/21.
//

import Foundation
import JWTDecode
import CoreImage

struct Tokens: Codable {
    var refresh: String
    var access: String
}

class CredentialManager {
    static let shared = CredentialManager()
    private var username: String = "guest"
    private let queue = DispatchQueue(label: "credential", qos: .userInteractive)
    private var lock = pthread_rwlock_t()
    
    let url = URL(string: "https://linglingwannabe.com/user/refresh")!
    
    private init() {
        pthread_rwlock_init(&lock, nil)
        if let token = getRefreshToken() {
            do {
                let jwt = try decode(jwt: String(decoding: token, as: UTF8.self))
                username = jwt.subject ?? "guest"
            } catch {
                DataManager.shared.insertErrorMessage(isNetwork: false, message: "Failed to decode JWT\n\(error.localizedDescription)")
                print("Failed to decode JWT\n\(error.localizedDescription)")
                delete()
            }
        }
    }
    
    func getUsername() -> String {
        pthread_rwlock_rdlock(&lock)
        let ret = username
        pthread_rwlock_unlock(&lock)
        return ret
    }
    
    // token must be in the format of ['refresh': refresh_token, 'access': access_token]
    func saveToKeyChain(token: Tokens) {
        queue.async {
            self.saveToKeyChainHelper(token: token.refresh, isRefresh: true)
            self.saveToKeyChainHelper(token: token.access, isRefresh: false)
        }
    }
    
    private func saveToKeyChainHelper(token: String, isRefresh: Bool) {
        let tokenType: String
        if isRefresh {
            tokenType = "refresh"
        } else {
            tokenType = "access"
        }
        let attrs = [kSecClass: kSecClassGenericPassword,
               kSecAttrService: tokenType,
               kSecAttrAccount: "com.zxxz",
                 kSecValueData: Data(token.utf8),
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock] as CFDictionary
        let status = SecItemAdd(attrs, nil)
        if status != errSecSuccess {
            if status == errSecDuplicateItem {
                let query = [kSecClass: kSecClassGenericPassword,
                       kSecAttrService: tokenType,
                       kSecAttrAccount: "com.zxxz"] as CFDictionary
                if (SecItemUpdate(query, [kSecValueData: Data(token.utf8)] as CFDictionary) != errSecSuccess) {
                    DataManager.shared.insertErrorMessage(isNetwork: false, message: "Failed to update KeyChain")
                }
            } else {
                DataManager.shared.insertErrorMessage(isNetwork: false, message: "Failed to insert into KeyChain")
            }
        }
        do {
            let jwt = try decode(jwt: token)
            if let sub = jwt.subject {
                pthread_rwlock_wrlock(&lock)
                username = sub
                pthread_rwlock_unlock(&lock)
            }
        } catch {
            DataManager.shared.insertErrorMessage(isNetwork: false, message: "Failed to decode JWT\n\(error.localizedDescription)")
            print("Failed to decode JWT\n\(error.localizedDescription)")
            delete()
        }
    }
    
    // return access token, may request new access token using refresh token and save new token(s) into KeyChain
    func getToken() -> String? {
        var ret: String? = nil
        queue.sync {
            if let access = self.getAccessToken() {
                ret = String(data: access, encoding: .utf8)
            } else {
                print("didn't get access token, attempt to refresh")
                guard let refreshD = self.getRefreshToken() else { return }
                guard let refresh = String(data: refreshD, encoding: .utf8) else { return }
                let semaphore = DispatchSemaphore(value: 0)
                postJSON(url: url, json: ["refresh": refresh], success: { data, res in
                    if res.statusCode == 200 {
                        var json: Any? = nil
                        do {
                            json = try JSONSerialization.jsonObject(with: data)
                        } catch {
                            print(error.localizedDescription)
                        }
                        if let tmp = json as? [String:String] {
                            if let accessT = tmp["access"] {
                                ret = accessT
                                self.saveToKeyChainHelper(token: accessT, isRefresh: false)
                            }
                            if let refreshT = tmp["refresh"] {
                                self.saveToKeyChainHelper(token: refreshT, isRefresh: true)
                            }
                        }
                    }
                    if res.statusCode == 403 || res.statusCode == 401 {
                        self.delete()
                        pthread_rwlock_wrlock(&(self.lock))
                        self.username = "guest"
                        pthread_rwlock_unlock(&(self.lock))
                    }
                    semaphore.signal()
                }, failure: { err in
                    print(err.localizedDescription)
                    semaphore.signal()
                })
                semaphore.wait()
            }
        }
        return ret
    }
    
    private func getAccessToken() -> Data? {
        let query = [kSecClass: kSecClassGenericPassword,
               kSecAttrService: "access",
               kSecAttrAccount: "com.zxxz",
                kSecReturnData: true] as CFDictionary
        var res: AnyObject? = nil
        SecItemCopyMatching(query, &res)
        if res == nil {
            return nil
        }
        do {
            guard let resD = res as? Data else { return nil }
            let jwt = try decode(jwt: String(decoding: resD, as: UTF8.self))
            if !jwt.expired {
                return resD
            }
        } catch {
            DataManager.shared.insertErrorMessage(isNetwork: false, message: "Failed to decode JWT\n\(error.localizedDescription)")
            print("Failed to decode JWT\n\(error.localizedDescription)")
            delete()
        }
        return nil
    }
    
    private func getRefreshToken() -> Data? {
        let query = [kSecClass: kSecClassGenericPassword,
               kSecAttrService: "refresh",
               kSecAttrAccount: "com.zxxz",
                kSecReturnData: true] as CFDictionary
        var res: AnyObject? = nil
        SecItemCopyMatching(query, &res)
        return res as? Data
    }
    
    func delete() {
        let refresh = [kSecClass: kSecClassGenericPassword,
                 kSecAttrService: "refresh",
                 kSecAttrAccount: "com.zxxz"] as CFDictionary
        SecItemDelete(refresh)
        let access = [kSecClass: kSecClassGenericPassword,
                 kSecAttrService: "access",
                 kSecAttrAccount: "com.zxxz"] as CFDictionary
        SecItemDelete(access)
        username = "guest"
    }
}

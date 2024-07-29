//
//  ApiKey.swift
//  visionos-example
//
//  Created by coji on 2024/07/29.
//
import Foundation
import Security

private let SERVICE = "jp.techtalk.visionos-example"
private let ACCOUNT = "openai_api_key"

struct ApiKeyService {
  static func saveApiKey(_ apiKey: String) {
    let keychainQuery: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: SERVICE,
      kSecAttrAccount as String: ACCOUNT,
    ]

    let updateAttributes: [String: Any] = [
      kSecValueData as String: apiKey.data(using: .utf8)!,
    ]

    let status = SecItemUpdate(keychainQuery as CFDictionary, updateAttributes as CFDictionary)

    if(status == errSecItemNotFound) {
      var newItem = keychainQuery
      newItem[kSecValueData as String] = apiKey.data(using: .utf8)!
      SecItemAdd(keychainQuery as CFDictionary, nil)
    }
  }

  static func getApiKey() -> String? {
    let keychainQuery: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: SERVICE,
      kSecAttrAccount as String: ACCOUNT,
      kSecReturnData as String: kCFBooleanTrue!,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var dataTypeRef: AnyObject? = nil
    let status: OSStatus = SecItemCopyMatching(keychainQuery as CFDictionary, &dataTypeRef)
    if status == noErr, let data = dataTypeRef as? Data, let apiKey = String(data: data, encoding: .utf8)
    {
      return apiKey
    }
    return nil
  }
}

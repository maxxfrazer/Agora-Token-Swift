//
//  Agora-Swift-Token.playground
//
//
//  Created by Max Cobb on 08/10/2020.
//

import Foundation
import Dispatch

/// - Parameters:
///   - domain: Domain which is hosting the Agora Token Server (ie http://localhost:8080)
///   - channelName: Name of the channel the token will allow the user to access
///   - userId: User ID requesting to join the server. A value of 0 works for all users.
/// - Returns: A new token which will expire in 24 Hours, or however specified by the token server.
///            An empty string response means that this function has failed.
func fetchRTCToken(domain: String, channelName: String, userId: UInt = 0) -> String {
    // Construct the endpoint URL
    guard let endURL = URL(string: "\(domain)/rtc/\(channelName)/publisher/uid/\(userId)/") else {
        return ""
    }
    /// semaphore is used to wait for the request to complete, before returning the token.
    let semaphore = DispatchSemaphore(value: 0)
    var request = URLRequest(url: endURL, timeoutInterval: 10)
    request.httpMethod = "GET"
    var tokenToReturn = ""
    
    // Construct the GET request
    let task = URLSession.shared.dataTask(with: request) { data, response, err in
        defer {
            // Signal that the request has completed
            semaphore.signal()
        }
        guard let data = data else {
            // No data, no token
            return
        }
        let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
        if let responseDict = responseJSON as? [String: Any], let token = responseDict["rtcToken"] as? String {
            // Key "rtcToken" found in response, assigning to tokenToReturn
            tokenToReturn = token
        }
    }
    
    task.resume()
    
    // Waiting for signal found inside the GET request handler
    semaphore.wait()
    return tokenToReturn
}

fetchRTCToken(domain: "http://localhost:8080", channelName: "my-channel", userId: 0)

# Fetching RTC/RTM Tokens with Swift

## Intro


When using the Agora platform, a good way to have a layer of security on your stream could be to add a token service.
In this tutorial, you will be shown how to fetch an Agora token from a web service running an Agora token server. 
To jump straight to a full iOS app which requests a token from a specified Agora Token Server, see the following repository:
https://github.com/maxxfrazer/Agora-iOS-Swift-Example


## Prerequisites
- An Agora Developer Account (see: [How To Get Started with Agora](https://www.agora.io/en/blog/how-to-get-started-with-agora?utm_source=medium&utm_medium=blog&utm_campaign=Fetching_RTC-RTM_Tokens_with_Swift))
- A basic understanding of iOS development using Swift
- Latest version of Xcode (see: [Xcode from Apple](https://developer.apple.com/xcode/))
- An Agora token server, either local or remote (see: [Agora Token Service](https://github.com/AgoraIO-Community/agora-token-service))
- A macOS or iOS app using the Agora macOS or iOS SDK respectively.

## Project Setup

A previous article has been written on how to create a token server, which can be found here. To quickly launch a token server, this GitHub repository has all the code laid out to do so already:

https://github.com/AgoraIO-Community/agora-token-service

Once you have your token server set up, you now need to pull that into your application; this article quickly shows you how to achieve this in Swift.

## Fetching the Token


You will need to determine the full URL to reach your token service. In my example, the service is running on the local machine, which is why I’m looking at `http://localhost:8080/…`<br>
I'm also using `my-channel` as the channel name, and `0` as the userId.

```swift
guard let tokenServerURL = URL(
    string: "http://localhost:8080/rtc/my-channel/publisher/uid/0/"
) else {
    return
}
```
<br>

Next we need to make a request; for this I'm using [`URLRequest`](https://developer.apple.com/documentation/foundation/urlrequest) from [`Foundation`](https://developer.apple.com/documentation/foundation). Set the request's httpMethod to `"GET"`, create the task using `URLSession.shared.dataTask` then start the task using `task.`[`resume()`](https://developer.apple.com/documentation/foundation/urlsessiontask/1411121-resume), as such:

```swift
var request = URLRequest(url: tokenServerURL, timeoutInterval: 10)
request.httpMethod = "GET"

let task = URLSession.shared.dataTask(
    with: request
) { data, response, err in
    // data task body here
}

task.resume()
```

Inside the data task body is where we can fetch the returned token. We can put something like this:

```swift
guard let data = data else {
    // No data, no token
    return
}

// parse response into json
let responseJSON = try? JSONSerialization.jsonObject(
    with: data, options: []
) as? [String: Any]

// check that json has key "rtcToken"
if let token = responseJSON?["rtcToken"] as? String {
    // Key "rtcToken" found in response, assigning to tokenToReturn
    print("the token is: \(token)")
}
```
<br>

Note that the main method may have already returned by the time the token reaches our device, so in the full example below I have added a [DispatchSemaphore](https://developer.apple.com/documentation/dispatch/dispatchsemaphore), which is used to hold on until we have the response. This way we can return the token straight from the method, but this will be blocking, so do not run this on the main thread if you don't have to.

<br>

---

<br>

## Full Example

```swift
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
    guard let tokenServerURL = URL(string: "\(domain)/rtc/\(channelName)/publisher/uid/\(userId)/") else {
        return ""
    }
    /// semaphore is used to wait for the request to complete, before returning the token.
    let semaphore = DispatchSemaphore(value: 0)
    var request = URLRequest(url: tokenServerURL, timeoutInterval: 10)
    request.httpMethod = "GET"
    var tokenToReturn = ""
    
    // Construct the GET request
    let task = URLSession.shared.dataTask(with: request) { data, response, err in
        // defer tells the function to run this when the method returns or otherwise finishes
        defer {
            // Signal that the request has completed
            semaphore.signal()
        }
        guard let data = data else {
            // No data, no token
            return
        }
        let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        if let token = responseJSON?["rtcToken"] as? String {
            // Key "rtcToken" found in response, assigning to tokenToReturn
            tokenToReturn = token
        }
    }
    
    task.resume()
    
    // Waiting for signal found inside the GET request handler
    semaphore.wait()
    return tokenToReturn
}
```

Be sure to make use of the other two parameters, response and err when adding this to your own project, as they are helpful for making sure the response from your token server is valid, and can let you know what may have gone wrong.

---

Try the file `Agora-Swift-Token.playground` to execute the above method on your own machine to see the token being retrieved from your server.

If you have Xcode installed, try the file Agora-Swift-Token.playground found in the [Agora-Token-Swift](https://github.com/maxxfrazer/Agora-Token-Swift) repository to execute the above method on your own machine to see the token being retrieved from your server.

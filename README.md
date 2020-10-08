# Retrieving Token in Swift

When using the Agora platform, a good way to have a layer of security on your stream could be to add a token service.
A previous article has been written on how to create a token server, [which can be found here](https://www.agora.io/en/blog/how-to-build-a-token-server-using-golang/). If you just want to launch a token server this GitHub repository has all the code laid out to do so already:
https://github.com/AgoraIO-Community/agora-token-service

Once you have your token server set up, you now need to pull that into your application; this article quickly shows you how to achieve this in Swift.

## Fetching the Token

First you need to determine the full URL to reach your token service. In my example, the service is running on the local machine, which is why I'm looking at localhost. I'm also using `my-channel` as the channel name, and `0` as the userId.

```swift
guard let tokenServerURL = URL(string: "http://localhost:8080/rtc/my-channel/publisher/uid/0/") else {
    return
}
```

Next we need to make a request; for this I'm using `[URLRequest](https://developer.apple.com/documentation/foundation/urlrequest)`. Set the request's httpMethod to `"GET"`, create the task and start it using the `[resume()](https://developer.apple.com/documentation/foundation/urlsessiontask/1411121-resume)` method as so:

```swift
var request = URLRequest(url: tokenServerURL, timeoutInterval: 10)
request.httpMethod = "GET"

let task = URLSession.shared.dataTask(with: request) { data, response, err in
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
let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])

// check that json has key "rtcToken"
if let responseDict = responseJSON as? [String: Any], let token = responseDict["rtcToken"] as? String {
    // Key "rtcToken" found in response
    print("the token is \(token)")
}
```

Note that the main method may have already returned by the time the token reaches our device, so in the full example below I have added a [DispatchSemaphore](https://developer.apple.com/documentation/dispatch/dispatchsemaphore), which is used to hold on until we have the response. This way we can return the token straight from the method, but this will be blocking, so do not run this on the main thread if you don't have to.


```swift
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
```

Be sure to make use of the other two parameters, response and err when adding this to your own project, as they are helpful for making sure the response from your token server is valid, and can let you know what may have gone wrong.

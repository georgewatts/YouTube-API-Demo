//
//  ViewController.swift
//  YTDemo
//
//  Created by Gabriel Theodoropoulos on 27/6/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var tblVideos: UITableView!
    
    @IBOutlet weak var segDisplayedContent: UISegmentedControl!
    
    @IBOutlet weak var viewWait: UIView!
    
    @IBOutlet weak var txtSearch: UITextField!
    
    
    var apiKey = "YOUR_API_KEY_HERE"
    
    var desiredChannelsArray = ["Apple", "Google", "Microsoft"]
    
    var channelIndex = 0
    
    var channelsDataArray: Array<Dictionary<String, String>> = []
    
    var videosArray = [[String:String]]()
    
    var selectedVideoIndex: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        tblVideos.delegate = self
        tblVideos.dataSource = self
        txtSearch.delegate = self
        
        getChannelDetails(useChannelIDParam: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "idSeguePlayer" {
            let playerViewController = segue.destination as! PlayerViewController
            playerViewController.videoID = videosArray[selectedVideoIndex]["videoID"]
        }
    }
    
    // MARK: IBAction method implementation
    
    @IBAction func segChangeContent(_ sender: Any) {
        tblVideos.reloadSections(NSIndexSet(index: 0) as IndexSet, with: UITableViewRowAnimation.fade)
    }
    
    // MARK: UITableView method implementation
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segDisplayedContent.selectedSegmentIndex == 0 {
            return channelsDataArray.count
        }
        else {
            return videosArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        
        if segDisplayedContent.selectedSegmentIndex == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "idCellChannel", for: indexPath)
            
            let channelTitleLabel = cell.viewWithTag(10) as! UILabel
            let channelDescriptionLabel = cell.viewWithTag(11) as! UILabel
            let thumbnailImageView = cell.viewWithTag(12) as! UIImageView
            
            let channelDetails = channelsDataArray[indexPath.row]
            channelTitleLabel.text = channelDetails["title"]
            channelDescriptionLabel.text = channelDetails["description"]
//            do {
//                thumbnailImageView.image = UIImage(data: Data(contentsOf: URL(string: channelDetails["thumbnail"]!)!))
//            }
//            catch {
//                print(error)
//            }
            
            let imageData = try? Data(contentsOf: URL(string: channelDetails["thumbnail"]!)!)
            
            if(imageData != nil) {
                thumbnailImageView.image = UIImage(data: imageData!)
            }
            //thumbnailImageView.image = UIImage(data: NSData(contentsOf: (URL(string: (channelDetails["thumbnail"] as? String)!))!) as Data
            //thumbnailImageView.image = UIImage(data: NSData(contentsOf: channelDetails["thumbnail"] as URL) as Data)
        }
        else {
            cell = tableView.dequeueReusableCell(withIdentifier: "idCellVideo", for: indexPath)
            
            let videoTitle = cell.viewWithTag(10) as! UILabel
            let videoThumbnail = cell.viewWithTag(11) as! UIImageView
            
            let videoDetails = videosArray[indexPath.row]
            
            videoTitle.text = videoDetails["title"]
            
            let imageData = try? Data(contentsOf: URL(string: videoDetails["thumbnail"]!)!)
            
            if(imageData != nil) {
                videoThumbnail.image = UIImage(data: imageData!)
            }
            
            //videoThumbnail.image = UIImage(data: NSData(contentsOfURL: NSURL(string: (videoDetails["thumbnail"] as? String)!)! as URL)!)
        }
        
        return cell
    }
    
    private func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 240.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if segDisplayedContent.selectedSegmentIndex == 0 {
            // In this case the channels are the displayed content.
            // The videos of the selected channel should be fetched and displayed.
            
            // Switch the segmented control to "Videos".
            segDisplayedContent.selectedSegmentIndex = 1
            tblVideos.reloadSections(NSIndexSet(index: 0) as IndexSet, with: UITableViewRowAnimation.fade)
            
            // Show the activity indicator.
            viewWait.isHidden = false
            
            // Remove all existing video details from the videosArray array.
            videosArray.removeAll(keepingCapacity: false)
            
            // Fetch the video details for the tapped channel.
            getVideosForChannelAtIndex(index: indexPath.row)
            segChangeContent(self)
        }
        else {
            selectedVideoIndex = indexPath.row
            performSegue(withIdentifier: "idSeguePlayer", sender: self)
        }
    }
    
    
    // MARK: UITextFieldDelegate method implementation
    
    private func textFieldShouldReturn(textField: UITextField) -> Bool {
    textField.resignFirstResponder()
        viewWait.isHidden = false
    
    // Specify the search type (channel, video).
    var type = "channel"
    if segDisplayedContent.selectedSegmentIndex == 1 {
        type = "video"
        videosArray.removeAll(keepingCapacity: false)
    }
    
    // Form the request URL string.
    var urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(String(describing: textField.text))&type=\(type)&key=\(apiKey)"
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    
    // Create a NSURL object based on the above string.
    let targetURL = NSURL(string: urlString)
    
    // Get the results.
    performGetRequest(targetURL: targetURL, completion: { (data, HTTPStatusCode, error) -> Void in
        if HTTPStatusCode == 200 && error == nil {
            // Convert the JSON data to a dictionary object.
            do {
                let resultsDict = try JSONSerialization.jsonObject(with: data! as Data, options: []) as! Dictionary<String, AnyObject>
                
                // Get all search result items ("items" array).
                let items: [Dictionary<String, String>] = resultsDict["items"] as! [Dictionary<String, String>]//<Dictionary<String, String>>)
                
                // Loop through all search results and keep just the necessary data.
                
                for dict in items {
                    let snippetDict = dict["snippet"]// as Dictionary<String, String>
                    
                    
                    
                    if self.segDisplayedContent.selectedSegmentIndex == 0 {
                        //self.desiredChannelsArray.append(snippetDict["channelId"]!)
                    }
                }
                
//                for var i=0; i<items.count; i++ {
//                    //let snippetDict = items[i]["snippet"] as! Dictionary<String, String>
//
//                    // Gather the proper data depending on whether we're searching for channels or for videos.
//                    if self.segDisplayedContent.selectedSegmentIndex == 0 {
//                        // Keep the channel ID.
//                        self.desiredChannelsArray.append(snippetDict["channelId"] as! String)
//                    }
//                    else {
//                        // Create a new dictionary to store the video details.
//                        var videoDetailsDict = Dictionary<NSObject, AnyObject>()
//                        videoDetailsDict["title"] = snippetDict["title"]
//                        videoDetailsDict["thumbnail"] = ((snippetDict["thumbnails"] as! Dictionary<NSObject, AnyObject>)["default"] as! Dictionary<NSObject, AnyObject>)["url"]
//                        videoDetailsDict["videoID"] = (items[i]["id"] as! Dictionary<NSObject, AnyObject>)["videoId"]
//
//                        // Append the desiredPlaylistItemDataDict dictionary to the videos array.
//                        self.videosArray.append(videoDetailsDict as! [String : AnyObject])
//
//                        // Reload the tableview.
//                        self.tblVideos.reloadData()
//                    }
//                }
            } catch {
                print(error)
            }
            
            // Call the getChannelDetails(…) function to fetch the channels.
            if self.segDisplayedContent.selectedSegmentIndex == 0 {
                self.getChannelDetails(useChannelIDParam: true)
            }
            
        }
        else {
            print("HTTP Status Code = \(HTTPStatusCode)")
            print("Error while loading channel videos: \(String(describing: error))")
        }
        
        // Hide the activity indicator.
            self.viewWait.isHidden = true
    })
    
    
    return true
}
    
    
    // MARK: Custom method implementation
    
    func performGetRequest(targetURL: NSURL!, completion: @escaping (_ data: NSData?, _ HTTPStatusCode: Int, _ error: NSError?) -> Void) {
        let request = NSMutableURLRequest(url: targetURL as URL)
        request.httpMethod = "GET"
        
        let sessionConfiguration = URLSessionConfiguration.default
        
        let session = URLSession(configuration: sessionConfiguration)
        
//        let task = session.dataTaskWithRequest(request as URLRequest, completionHandler: { (data: NSData?, response: URLResponse?, error: NSError?) -> Void in
//            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                completion(data as! NSData, (response as! HTTPURLResponse).statusCode, error! as!! NSError)
//            })
//        })
        
        let task = session.dataTask(with: targetURL as URL) { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            //dispatch_async(dispatch_get_main_queue(), )
            DispatchQueue.main.async(execute: {
                completion(data! as NSData, (response as! HTTPURLResponse).statusCode, error as NSError?)
            })
        }
        
        task.resume()
    }
    
    
    func getChannelDetails(useChannelIDParam: Bool) {
        var urlString: String!
        if !useChannelIDParam {
            urlString = "https://www.googleapis.com/youtube/v3/channels?part=contentDetails,snippet&forUsername=\(desiredChannelsArray[channelIndex])&key=\(apiKey)"
        }
        else {
            urlString = "https://www.googleapis.com/youtube/v3/channels?part=contentDetails,snippet&id=\(desiredChannelsArray[channelIndex])&key=\(apiKey)"
        }
        
        let targetURL = NSURL(string: urlString)
        
        performGetRequest(targetURL: targetURL, completion: { (data, HTTPStatusCode, error) -> Void in
            if HTTPStatusCode == 200 && error == nil {
                
                do {
                    // Convert the JSON data to a dictionary.
                    let resultsDict = try JSONSerialization.jsonObject(with: data! as Data, options: []) as! [String:AnyObject]
                    
                    // For our query in YouTube v3 API, items is an array of 1 dictionary
                    let items: [AnyObject] = resultsDict["items"] as! [AnyObject]
                    
                    // Get the dictionary from items
                    let itemsDict = (items)[0] as! [String:AnyObject]
                    
                    // Store the snippet portion
                    //let itemsSnippet = itemsDict["snippit"]
                    
                    //let firstItemDict = (items as! Array<String>)[0] as! Dictionary<String, String>
                    
                    // Get the snippet dictionary that contains channel specific details
                    let snippetDict = itemsDict["snippet"] as! [String:AnyObject]
                    
                    // Get the content details dictionary that contains the content specifc details
                    let contentDetailsDict = itemsDict["contentDetails"] as! [String:AnyObject]
                    
                    // Create a new dictionary to store only the values we care about.
                    var desiredValuesDict = [String:String]()
                    
                    desiredValuesDict["title"] = snippetDict["title"] as? String
                    desiredValuesDict["description"] = snippetDict["description"] as? String
                    
                    let thumbnailsDict = snippetDict["thumbnails"] as? [String:[String:String]]
                    
                    desiredValuesDict["thumbnail"] = thumbnailsDict!["default"]?["url"]// as? String //as [String:String]// as! Dictionary<String, String>)["url"]
                    
                    // Save the channel's uploaded videos playlist ID.
                    //desiredValuesDict["playlistID"] = (firstItemDict["contentDetails"])// as! Dictionary<String, String>)["relatedPlaylists"])// as! Dictionary<String, String>)["uploads"]
                    
                    desiredValuesDict["playlistID"] = contentDetailsDict["relatedPlaylists"]?["uploads"] as? String
                    
                    // Append the desiredValuesDict dictionary to the following array.
                    self.channelsDataArray.append(desiredValuesDict)
                    
                    // Reload the tableview.
                    self.tblVideos.reloadData()
                    
                    // Load the next channel data (if exist).
                    self.channelIndex += 1
                    if self.channelIndex < self.desiredChannelsArray.count {
                        self.getChannelDetails(useChannelIDParam: useChannelIDParam)
                    }
                    else {
                        self.viewWait.isHidden = true
                    }
                } catch {
                    print(error)
                }
                
            } else {
                print("HTTP Status Code = \(HTTPStatusCode)")
                print("Error while loading channel details: \(String(describing: error))")
            }
        })
    }

    
    func getVideosForChannelAtIndex(index: Int!) {
        // Get the selected channel's playlistID value from the channelsDataArray array and use it for fetching the proper video playlst.
        let playlistID = channelsDataArray[index]["playlistID"]!// as! String
        
        // Form the request URL string.
        let urlString = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=\(playlistID)&key=\(apiKey)"
        
        // Create a NSURL object based on the above string.
        let targetURL = NSURL(string: urlString)
        
        // Fetch the playlist from Google.
        performGetRequest(targetURL: targetURL, completion: { (data, HTTPStatusCode, error) -> Void in
            if HTTPStatusCode == 200 && error == nil {
                do {
                    // Convert the JSON data into a dictionary.
                    let resultsDict = try JSONSerialization.jsonObject(with: data! as Data, options: []) as! [String:AnyObject]
                    
                    // Get all playlist items ("items" array).
                    let items: [[String:AnyObject]] = resultsDict["items"] as! [[String:AnyObject]]
                    
                    for dict in items {//as! [String:AnyObject] {
                        let playlistSnippetDict: [String:AnyObject] = dict["snippet"] as! [String:AnyObject]
                        
                        let thumbnailsDict = playlistSnippetDict["thumbnails"] as? [String:AnyObject]
                        
                        var desiredValuesDict = [String:String]()
                        
                        desiredValuesDict["title"] = playlistSnippetDict["title"] as? String
                        desiredValuesDict["thumbnail"] = thumbnailsDict!["default"]?["url"] as? String
                        desiredValuesDict["videoID"] = playlistSnippetDict["resourceId"]?["videoId"] as? String
                        
                        self.videosArray.append(desiredValuesDict)
                    }
                    
                    // Use a loop to go through all video items.
//                    for var i=0; i<items.count; ++i {
//                        let playlistSnippetDict = (items[i] as Dictionary<NSObject, AnyObject>)["snippet"] as! Dictionary<NSObject, AnyObject>
//
//                        // Initialize a new dictionary and store the data of interest.
//                        var desiredPlaylistItemDataDict = Dictionary<NSObject, AnyObject>()
//
//                        desiredPlaylistItemDataDict["title"] = playlistSnippetDict["title"]
//                        desiredPlaylistItemDataDict["thumbnail"] = ((playlistSnippetDict["thumbnails"] as! Dictionary<NSObject, AnyObject>)["default"] as! Dictionary<NSObject, AnyObject>)["url"]
//                        desiredPlaylistItemDataDict["videoID"] = (playlistSnippetDict["resourceId"] as! Dictionary<NSObject, AnyObject>)["videoId"]
//
//                        // Append the desiredPlaylistItemDataDict dictionary to the videos array.
//                        self.videosArray.append(desiredPlaylistItemDataDict as! [String : AnyObject])
//
//                        // Reload the tableview.
//                        self.tblVideos.reloadData()
//                    }
                } catch {
                    print(error)
                }
            }
            else {
                print("HTTP Status Code = \(HTTPStatusCode)")
                print("Error while loading channel videos: \(String(describing: error))")
            }
            
            // Hide the activity indicator.
            self.viewWait.isHidden = true
        })
    }
}


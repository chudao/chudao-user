//
//  ResponseProductDetailViewController.swift
//  chudao
//
//  Created by xuanlin yang on 7/21/16.
//  Copyright © 2016 chudao888. All rights reserved.
//

import UIKit

class ResponseProductDetailViewController: UIViewController {

    var userId: Int = -1
    var authToken: String = "undefined"
    var identity: String = "undefined"
    var username: String = "undefined"
    var password: String = "undefined"
    var productDetail: [[String:AnyObject]] = []
    var requestDetail: [String:AnyObject] = [:]
    var responseDetail: [String:AnyObject] = [:]
    var requestSpecificImageAsData = NSData()
    var userDefaultImageAsData = NSData()
    var stylistImageAsData = NSData()
    var prodcutIndex: Int = -1
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    @IBOutlet var productImage: UIImageView!
    @IBOutlet var productBrand: UILabel!
    @IBOutlet var productName: UILabel!
    @IBOutlet var productDescription: UILabel!
    @IBOutlet var purchaseButton: UIButton!
    @IBOutlet var doneButton: UIButton!
    @IBAction func done(sender: AnyObject) {
        performSegueWithIdentifier("productDetailToResponse", sender: self)
    }
    @IBAction func purchase(sender: AnyObject) {
        displayAlert("Redirecting", message: "You are being redirected to the merchandiser's website for purchase", enterMoreInfo: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("ResponseProductDetailpage userid: \(userId)")
        print("NeResponseProductDetailpagewRequest identity \(identity)")
        
        doneButton.layer.cornerRadius = 8.0
        doneButton.layer.masksToBounds = true
        doneButton.layer.borderColor = UIColor( red: 128/255, green: 128/255, blue:128/255, alpha: 1.0 ).CGColor
        doneButton.layer.borderWidth = 1.0
        
        purchaseButton.layer.cornerRadius = 8.0
        purchaseButton.layer.masksToBounds = true
        purchaseButton.layer.borderColor = UIColor( red: 128/255, green: 128/255, blue:128/255, alpha: 1.0 ).CGColor
        purchaseButton.layer.borderWidth = 1.0
        
        //activity indicator
        activityIndicator = UIActivityIndicatorView(frame: self.view.bounds)
        activityIndicator.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        view.addSubview(activityIndicator)
        
        productImage.clipsToBounds = true
        productImage.contentMode = UIViewContentMode.ScaleAspectFill

        productName.text = productDetail[prodcutIndex]["productName"] as? String
        productBrand.text = productDetail[prodcutIndex]["productBrand"] as? String
        productDescription.text = productDetail[prodcutIndex]["productDescription"] as? String
        
        productImage.userInteractionEnabled = true
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ProductDetailViewController.imageTapped(_:)))
        productImage.addGestureRecognizer(tapRecognizer)
        
    }
    
    func imageTapped(sender: UITapGestureRecognizer) {
        let imageView = sender.view as! UIImageView
        let newImageView = UIImageView(image: imageView.image)
        newImageView.frame = self.view.frame
        newImageView.backgroundColor = .blackColor()
        newImageView.contentMode = .ScaleAspectFit
        newImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(ProductDetailViewController.dismissFullscreenImage(_:)))
        newImageView.addGestureRecognizer(tap)
        self.view.addSubview(newImageView)
    }
    
    func dismissFullscreenImage(sender: UITapGestureRecognizer) {
        sender.view?.removeFromSuperview()
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //redirect to merchandiser's website using default internet browser
    func redirect(){
        UIApplication.sharedApplication().openURL(NSURL(string: (productDetail[prodcutIndex]["productLink"] as? String)!)!)
    }
    
    //display alert
    func displayAlert(title: String, message: String, enterMoreInfo: Bool) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        if enterMoreInfo == true {
            alert.addAction(UIAlertAction(title: "Continue", style: UIAlertActionStyle.Default, handler: { (action) in
                self.redirect()
            }))
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    //query fileKey
    func queryFileKey(productId: String){
        //activate activity indicator and disable user interaction
        activityIndicator.startAnimating()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        
        // Setup the session to make REST POST call
        let postEndpoint: String = "http://chudao.herokuapp.com/query/file/product-ids"
        let url = NSURL(string: postEndpoint)!
        let session = NSURLSession.sharedSession()
        let postParams : [String: String] = ["product-ids": productId]
        
        // Create the request
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue(self.authToken, forHTTPHeaderField: "X-Auth-Token")
        
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(postParams, options: NSJSONWritingOptions())
            print("Request: \(postParams)")
        } catch {
            print("Error")
        }
        
        // Make the POST call and handle it in a completion handler
        session.dataTaskWithRequest(request) { (data: NSData?, response: NSURLResponse?, error: NSError?) in
            //disable activiy indicator and re-activate user interaction
            self.activityIndicator.stopAnimating()
            UIApplication.sharedApplication().endIgnoringInteractionEvents()
            
            // Make sure we get an OK response
            guard let realResponse = response as? NSHTTPURLResponse where
                realResponse.statusCode == 200 else {
                    print("Response code: \((response as? NSHTTPURLResponse)?.statusCode)")
                    return
            }
            
            
            // Read the JSON
            do{
                guard let jsonResponse = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? [String: AnyObject] else{
                    print("Error reading JSON data")
                    return
                }
                print(jsonResponse)
                if jsonResponse["response-code"]! as! String == "040" {
                    let productInfo = jsonResponse["response-data"] as? [[String:AnyObject]]
                    self.downloadImage(productInfo![0]["FileKey"] as! String)
                }else{
                    dispatch_async(dispatch_get_main_queue()) {
                        self.displayAlert("Unable to query", message: jsonResponse["response-message"]! as! String, enterMoreInfo: false)
                    }
                }
            }catch  {
                print("error trying to convert data to JSON")
                return
            }
            }.resume()
    }
    
    //download image by fileKey
    func downloadImage(fileKey: String){
        //activate activity indicator and disable user interaction
        dispatch_async(dispatch_get_main_queue()) {
            self.activityIndicator.startAnimating()
            UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        }
        
        // Setup the session to make REST POST call
        let postEndpoint: String = "http://chudao.herokuapp.com/binary/download"
        let url = NSURL(string: postEndpoint)!
        let session = NSURLSession.sharedSession()
        let postParams : [String: String] = ["file-name": fileKey]
        
        // Create the request
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.setValue(self.authToken, forHTTPHeaderField: "X-Auth-Token")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(postParams, options: NSJSONWritingOptions())
            print("Request: \(postParams)")
        } catch {
            print("Error")
        }
        
        // Make the POST call and handle it in a completion handler
        session.dataTaskWithRequest(request) { (data: NSData?, response: NSURLResponse?, error: NSError?) in
            //disable activiy indicator and re-activate user interaction
            dispatch_async(dispatch_get_main_queue()) {
                self.activityIndicator.stopAnimating()
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
            }
            
            // Make sure we get an OK response
            guard let realResponse = response as? NSHTTPURLResponse where
                realResponse.statusCode == 200 else {
                    print("Not a 200 Response, code: \((response as? NSHTTPURLResponse)?.statusCode)")
                    return
            }
            print("Response \(response)")
            
            if let image = UIImage(data: data!){
                dispatch_async(dispatch_get_main_queue()) {
                    self.productImage.image = image
                }
            }else{
                dispatch_async(dispatch_get_main_queue()) {
                    self.displayAlert("Unable to display image", message: "Sorry, we are having issue displaying the image", enterMoreInfo: false)
                }
            }
            }.resume()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "productDetailToResponse" {
            let destinationViewController = segue.destinationViewController as! ResponseProductDetailViewController
            destinationViewController.userId = userId
            destinationViewController.authToken = authToken
            destinationViewController.identity = identity
            destinationViewController.username = username
            destinationViewController.password = password
            destinationViewController.productDetail = productDetail
            destinationViewController.requestDetail = requestDetail
            destinationViewController.userDefaultImageAsData = userDefaultImageAsData
            destinationViewController.stylistImageAsData = stylistImageAsData
            destinationViewController.responseDetail = responseDetail
            destinationViewController.requestSpecificImageAsData = requestSpecificImageAsData
        }
    }

}

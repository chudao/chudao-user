//
//  ViewController.swift
//  chudao
//
//  Created by xuanlin yang on 6/17/16.
//  Copyright © 2016 chudao888. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UITextFieldDelegate {

    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    var identity: String = "undefined"
    var authToken: String = "undefined"
    
    @IBOutlet var switchToSignUp: UIButton!
    @IBOutlet var login: UIButton!
    @IBOutlet var username: UITextField!
    @IBOutlet var password: UITextField!
    @IBAction func loginButton(sender: AnyObject) {
        if username.text == "" || password.text == "" {
            displayAlert("Missing Field(s)", message: "Username and password are required")
        }else{
            postDataToURL()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        username.delegate=self
        password.delegate=self
        username.backgroundColor = UIColor .clearColor()
        password.backgroundColor = UIColor .clearColor()
        
        username.layer.cornerRadius = 8.0
        username.layer.masksToBounds = true
        username.layer.borderColor = UIColor( red: 128/255, green: 128/255, blue:128/255, alpha: 1.0 ).CGColor
        username.layer.borderWidth = 1.0
        
        password.layer.cornerRadius = 8.0
        password.layer.masksToBounds = true
        password.layer.borderColor = UIColor( red: 128/255, green: 128/255, blue:128/255, alpha: 1.0 ).CGColor
        password.layer.borderWidth = 1.0
        
        login.layer.cornerRadius = 8.0
        login.layer.masksToBounds = true
        login.layer.borderColor = UIColor( red: 128/255, green: 128/255, blue:128/255, alpha: 1.0 ).CGColor
        login.layer.borderWidth = 1.0
        
        login.setTitleColor(UIColor.blackColor(), forState: .Normal)
        switchToSignUp.setTitleColor(UIColor.blackColor(), forState: .Normal)
        
        //gesture to dismiss keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        //activity indicator
        activityIndicator = UIActivityIndicatorView(frame: self.view.bounds)
        activityIndicator.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        view.addSubview(activityIndicator)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //dismiss keyboard by clicking anywhere else
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    //dimiss keyboard by pressing return key
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    //display alert
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func postDataToURL() {
        //activate activity indicator and disable user interaction
        dispatch_async(dispatch_get_main_queue()) {
            self.activityIndicator.startAnimating()
            UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        }
        
        
        // Setup the session to make REST POST call
        let postEndpoint: String = "http://chudao.herokuapp.com/auth/login"
        let url = NSURL(string: postEndpoint)!
        let session = NSURLSession.sharedSession()
        let postParams : [String: String] = ["user-name": self.username.text!, "password": self.password.text!]
        
        // Create the request
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(postParams, options: NSJSONWritingOptions())
            print(postParams)
        } catch {
            print("bad things happened")
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
                    print("Not a 200 response, code: \((response as? NSHTTPURLResponse)?.statusCode)")
                    return
            }

            
            
            if let postString = NSString(data:data!, encoding: NSUTF8StringEncoding) as? String {
                    // Print what we got from the call
                    print("Response: " + postString)
            }
            
            // Read the JSON
            do{
                guard let jsonResponse = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? [String: AnyObject] else{
                    print("Error reading JSON data")
                    return
                }
                if jsonResponse["response-code"]! as! String == "000" {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.authToken = ((response as? NSHTTPURLResponse)?.allHeaderFields["X-Auth-Token"] as? String)!
                        print("Token \(self.authToken)")
                        let userId = jsonResponse["user-id"]! as! Int
                        self.identity = jsonResponse["user-category"] as! String
                        self.performSegueWithIdentifier("loginToHome", sender: userId)
                    }
                }else{
                    dispatch_async(dispatch_get_main_queue()) {
                        self.displayAlert("Unable to login", message: jsonResponse["response-message"]! as! String)
                    }
                }
            }catch  {
                print("error trying to convert data to JSON")
                return
            }
        }.resume()
    }

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "loginToHome" {
            let destinationViewController = segue.destinationViewController as! UITabBarController
            let destinationTab = destinationViewController.viewControllers?.first as! HomeViewController
            destinationTab.userId = sender as! Int
            destinationTab.identity = identity
            destinationTab.authToken = authToken
            destinationTab.username = username.text!
            destinationTab.password = password.text!
        }
    }
}


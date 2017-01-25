//
//  ViewController.swift
//  connect_api
//
//  Created by Mateo Marin on 12/6/16.
//  Copyright © 2016 Mateo Marin. All rights reserved.
//

import UIKit
import ACHOnFileIosSDK

class MenuController: UIViewController {
    
    var apiKey: String?
    var apiSecret: String?
    var token: String?
    var url: String?
    var client:FirstApiClient?
    var enrollmentId:String?
    
    //ui connectors
    @IBOutlet weak var processing: UIActivityIndicatorView!
    @IBOutlet weak var enrollmentLabel: UILabel!
    @IBOutlet weak var amountLabel: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apiKey = "y6pWAJNyJyjGv66IsVuWnklkKUPFbb0a"
        apiSecret = "2b940ece234ee38131e70cc617aa2afa3d7ff8508856917958e7feb3ef190447"
        token = "fdoa-a480ce8951daa73262734cf102641994c1e55e7cdf4c02b6"
        url = "https://api-cert.payeezy.com/"
        
        client = FirstApiClient(apiKey: self.apiKey!, token: self.token!, apiUrl: self.url!, apiSecret: self.apiSecret!, controller: self)

    }
    
    //delegate method to pass enrollmentID from RegularController back
    func setEnrollmentID(enrollmentId: String) {
        self.enrollmentId = enrollmentId
        self.enrollmentLabel.text = enrollmentId
    }
    
    //segue button for regular enrollment
    @IBAction func enrollSegue(_ sender: UIButton) {
        client?.regularEnrollment(onCompletion: {(id)->Void in
            self.setEnrollmentID(enrollmentId: id)
        })
    }
    
    @IBAction func pwmbSegue(_ sender: UIButton) {
        client?.performEnrollmentWithPayWithMyBank(onSuccess: {(response, error) -> Void in
            print("done")
            self.setEnrollmentID(enrollmentId: response!)
        })
    }
    //transaction call
    @IBAction func performTransaction(_ sender: UIButton) {
        self.client?.performTransaction(enrollmentId: self.enrollmentId, amount: self.amountLabel.text, onCompletion: {(transactionId, refundId, error)->Void in
            if(error != nil){print(error!)}
            else {
                print(transactionId!)
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

//
//  RegularEnrollmentForm.swift
//  connect_api
//
//  Created by Mateo Marin on 12/26/16.
//  Copyright © 2016 Mateo Marin. All rights reserved.
//

import UIKit

class RegularEnrollmentForm: UIView {

    let nibName:String = "RegularEnrollmentForm"
    var view:UIView!
    var cancel: (()->Void)?
    var enroll: ((_ data: NSDictionary?, _ error: String?)->Void)?
    
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var accountNumber: UITextField!
    @IBOutlet weak var routingNumber: UITextField!
    
    @IBAction func enrollRegular(_ sender: UIButton) {
        if(self.firstName.hasText && self.lastName.hasText && self.accountNumber.hasText && self.routingNumber.hasText){
            let enrollRequest = EnrollmentRequest()
            enrollRequest.first = firstName.text
            enrollRequest.last = lastName.text
            enrollRequest.user.accountNumber = accountNumber.text!
            enrollRequest.user.routingNumber = routingNumber.text!
            enroll?(enrollRequest.json(), nil)
        } else {
            enroll?(nil, "Fill all fields in form")
        }
    }
    
    @IBAction func dismissView(_ sender: UIBarButtonItem) {
        cancel?()
    }
    
    func setup() {
        self.view = UINib(nibName: self.nibName, bundle:
            Bundle(for:type(of: self))).instantiate(withOwner: self, options: nil)[0] as! UIView
        self.view.frame = bounds
        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(self.view)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

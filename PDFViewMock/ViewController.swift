//
//  ViewController.swift
//  PDFViewMock
//
//  Created by naoyuki.kan on 2023/03/17.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var DisplayPDFViewButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    @IBAction func tappedDisplayPDFView(_ sender: Any) {
        let vc = PDFViewViewController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}


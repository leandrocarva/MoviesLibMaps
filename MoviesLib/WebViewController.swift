//
//  WebViewController.swift
//  MoviesLib
//
//  Created by Usuário Convidado on 04/04/18.
//  Copyright © 2018 EricBrito. All rights reserved.
//

import UIKit

class WebViewController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    var url: String!
    
    @IBAction func Close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func runJS(_ sender: Any) {
      webView.stringByEvaluatingJavaScript(from: "alert('Rodando Javascript na WebView')")
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        let webpageURL = URL(string: url)
        let request = URLRequest(url: webpageURL!)
        webView.loadRequest(request)
        
        
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    

}

extension WebViewController: UIWebViewDelegate {
    func webViewDidFinishLoad(_ webView: UIWebView) {
      loading.stopAnimating()
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        //Filtrando o app para não abrir site porno por exemplo
        if request.url!.absoluteString.range(of: "sex") != nil {
            return false
        }
        return true
    }
}

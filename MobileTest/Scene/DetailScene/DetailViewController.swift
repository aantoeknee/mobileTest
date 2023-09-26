//
//  DetailViewController.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/26/23.
//

import UIKit
import youtube_ios_player_helper

class DetailViewController: UIViewController {

    @IBOutlet weak var playerView: YTPlayerView!

    override func viewDidLoad() {
        super.viewDidLoad()
        playerView.load(withVideoId: "QlcPVitKjOM")
    }
}

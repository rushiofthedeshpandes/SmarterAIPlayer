//
//  ViewController.swift
//  SmarterAIPlayer
//
//  Created by Rushikesh Deshpande on 26/07/24.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var videoPlayerView: UIView!
    @IBOutlet weak var videoPlayerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var controlsView: UIView!
    @IBOutlet weak var labelCurrentTime: UILabel!
    @IBOutlet weak var labelDuration: UILabel!
    @IBOutlet weak var playerVideoStatus: UILabel!
    @IBOutlet weak var imageViewPrevious: UIImageView!{
        didSet {
            self.imageViewPrevious.isUserInteractionEnabled = true
            self.imageViewPrevious.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                                          action: #selector(playPreviousVideo)))
        }
    }
    @IBOutlet weak var imageViewRewind: UIImageView! {
        didSet {
            self.imageViewRewind.isUserInteractionEnabled = true
            self.imageViewRewind.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                                          action: #selector(rewindTapped)))
        }
    }
    @IBOutlet weak var imageViewPlay: UIImageView! {
        didSet {
            self.imageViewPlay.isUserInteractionEnabled = true
            self.imageViewPlay.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                                     action: #selector(playPauseTapped)))
        }
    }
    @IBOutlet weak var imageViewForward: UIImageView! {
        didSet {
            self.imageViewForward.isUserInteractionEnabled = true
            self.imageViewForward.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                                         action: #selector(forwardTapped)))
        }
    }
    @IBOutlet weak var imageViewNext: UIImageView!{
        didSet {
            self.imageViewNext.isUserInteractionEnabled = true
            self.imageViewNext.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                                         action: #selector(playNextVideo)))
        }
    }
    @IBOutlet weak var seekbar: UISlider! {
        didSet {
            self.seekbar.addTarget(self,
                                      action: #selector(onSlide),
                                      for: .valueChanged)
        }
    }
    @IBOutlet weak var imageViewFullScreen: UIImageView! {
        didSet {
            self.imageViewFullScreen.isUserInteractionEnabled = true
            self.imageViewFullScreen.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                                                 action: #selector(toggleFullScreenTapped)))
        }
    }

    // AVPlayer
    private var player : AVPlayer? = nil
    private var playerLayer : AVPlayerLayer? = nil
    private var playerItem: AVPlayerItem?
    private var timeObserver : Any? = nil
    private var isThumbSeek : Bool = false
    
    // Video Data
    private var videoData: VideoData?
    private var currentVideoIndex: Int = 0
    private var playerObserver: Any?
    
    // Helper Vars
    var isShown = true

    //MARK: - VIEW CONTROLLER LIFE CYCLE METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        videoData = VideoDataViewModel.loadJSONData()
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: self.player?.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemFailedToPlay(_:)),
                                               name: .AVPlayerItemFailedToPlayToEndTime,
                                               object: self.player?.currentItem)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        if InternetConnectionManager.isConnectedToNetwork(){
            playCurrentVideo()
        }else{
            showMessage("Please make sure you're connected to Wifi/mobile data network. ")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isShown{
            hideControls()
        }else{
            showControls()
        }
    }
    
    deinit{
        NotificationCenter.default.removeObserver(self)
    }
}

//MARK: - SMARTER AI PLAYER METHODS & FUNCTIONS

extension ViewController {
    @objc private func playerDidFinishPlaying(){
        playNextVideo()
    }
    
    @objc func playerItemFailedToPlay(_ notification: Notification) {
        let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
        showMessage(error!.localizedDescription)
    }
    
    private func startVideoPlayer(with videoURL : String) {
        guard InternetConnectionManager.isConnectedToNetwork() else { 
            showMessage("Please make sure you're connected to Wifi/mobile data network. ")
            return }
        guard let url = URL(string:videoURL) else { return }
        if self.player == nil {
            self.player = AVPlayer(url: url)
            self.playerLayer = AVPlayerLayer(player: self.player)
            self.playerLayer?.videoGravity = .resizeAspectFill
            self.playerLayer?.frame = self.videoPlayerView.frame
            self.playerLayer?.addSublayer(self.controlsView.layer)
            if let playerLayer = self.playerLayer {
                self.view.layer.addSublayer(playerLayer)
            }
            self.player?.play()
        }else{
            playerItem = AVPlayerItem(url: url)
            player?.replaceCurrentItem(with: playerItem)
            player?.play()
        }
        self.setObserverToPlayer()
    }
    
    private func setObserverToPlayer() {
        let interval = CMTime(seconds: 0.3, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, 
                                                       queue: .main,
                                                       using: { [weak self] elapsed in
            self?.updatePlayerTime()
        })
    }
    
    private func updatePlayerTime() {
        if player?.currentItem?.status == .readyToPlay {
            guard let currentTime = self.player?.currentTime() else { return }
            guard let duration = self.player?.currentItem?.duration else { return }
            let currentTimeInSecond = CMTimeGetSeconds(currentTime)
            let durationTimeInSecond = CMTimeGetSeconds(duration)
            DispatchQueue.main.async {
                if self.isThumbSeek == false {
                    self.seekbar.value = Float(currentTimeInSecond/durationTimeInSecond)
                }
                let value = Float64(self.seekbar.value) * CMTimeGetSeconds(duration)
                if let currentTime = Helper.getStringConversion(for: value){
                    self.labelCurrentTime.text = currentTime
                }
                if let duration = Helper.getStringConversion(for: durationTimeInSecond){
                    self.labelDuration.text = duration
                }
            }
        }
    }
    
    private func hideControls(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            UIView.animate(withDuration: 0.5, animations: {
                self.controlsView.alpha = 0
            }) { (finished) in
                self.isShown = false
            }
        }
    }

    private func showControls(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIView.animate(withDuration: 0.5, animations: {
                self.controlsView.alpha = 1
            }) { (finished) in
                self.hideControls()
            }
        }
    }

    @objc private func forwardTapped() {
        DispatchQueue.main.async {
            self.navigateVideo(by: 5)
        }
    }
    
    @objc private func rewindTapped() {
        DispatchQueue.main.async {
            self.navigateVideo(by: -5)
        }
    }
    
    private func navigateVideo(by value: Double){
        guard let currentTime = self.player?.currentTime() else { return }
        let seekTimeValue = CMTimeGetSeconds(currentTime).advanced(by: value)
        let seekTime = CMTime(value: CMTimeValue(seekTimeValue), timescale: 1)
        self.player?.seek(to: seekTime, completionHandler: { completed in
        })
    }
    
    private func playCurrentVideo() {
        self.labelDuration.text = "00:00"
        self.labelCurrentTime.text = "00:00"
        showControls()
        guard let recordings = videoData?.recordings else { return }
        if currentVideoIndex < recordings.count {
            let currentRecording = recordings[currentVideoIndex]
            self.playerVideoStatus.text = "\(currentVideoIndex+1) / \(recordings.count)"
            startVideoPlayer(with: currentRecording.url)
        }
    }
    
    fileprivate func updateCurrentIndex() {
        if currentVideoIndex < (videoData?.recordings.count ?? 0) {
        } else {
            player?.pause()
            currentVideoIndex = 0
        }
        playCurrentVideo()

    }
    
    @objc private func playNextVideo() {
        currentVideoIndex += 1
        updateCurrentIndex()
    }
    
    @objc private func playPreviousVideo() {
        currentVideoIndex -= 1
        if currentVideoIndex < 0 {
            currentVideoIndex = 0
        }
        updateCurrentIndex()
    }

    @objc private func playPauseTapped() {
        if self.player?.timeControlStatus == .playing {
            self.imageViewPlay.image = UIImage(systemName: "pause.circle")
            self.player?.pause()
        } else {
            self.imageViewPlay.image = UIImage(systemName: "play.circle")
            self.player?.play()
        }
    }
    
    @objc private func onSlide() {
        self.isThumbSeek = true
        if self.seekbar.isTracking == true {
        } else {
            guard let duration = self.player?.currentItem?.duration else { return }
            let value = Float64(self.seekbar.value) * CMTimeGetSeconds(duration)
            if value.isNaN == false {
                let seekTime = CMTime(value: CMTimeValue(value), timescale: 1)
                self.player?.seek(to: seekTime, completionHandler: { completed in
                    if completed {
                        self.isThumbSeek = false
                    }
                })
            }
        }
    }
}

//MARK: - DEVICE ORIENTATION (PORTRAIT TO LANDSCAPE & VICEVERSA) HANDLING METHODS
extension ViewController {
    private var windowInterface : UIInterfaceOrientation? {
        return self.view.window?.windowScene?.interfaceOrientation
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        guard let windowInterface = self.windowInterface else { return }
        if windowInterface.isPortrait ==  true {
            self.videoPlayerHeightConstraint.constant = 300
        } else {
            self.videoPlayerHeightConstraint.constant = self.view.layer.bounds.width
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            self.playerLayer?.frame = self.videoPlayerView.frame
        })
    }

    
    @objc private func toggleFullScreenTapped() {
        if #available(iOS 16.0, *) {
            handleOrientationForiOS16()
        } else {
            handleOrientationBelowiOS16()
        }
    }
    
    private func handleOrientationForiOS16(){
        guard let windowSceen = self.view.window?.windowScene else { return }
        if windowSceen.interfaceOrientation == .portrait {
            windowSceen.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape)) { error in
                print(error.localizedDescription)
            }
        } else {
            windowSceen.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { error in
                print(error.localizedDescription)
            }
        }
    }
    
    private func handleOrientationBelowiOS16(){
        if UIDevice.current.orientation == .portrait {
            let orientation = UIInterfaceOrientation.landscapeRight.rawValue
            UIDevice.current.setValue(orientation, forKey: "orientation")
        } else {
            let orientation = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(orientation, forKey: "orientation")
        }
    }
    
    func showMessage(_ message: String ){
        let alertController = UIAlertController(title: "Error !", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay", style: .default) { _ in
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}

       

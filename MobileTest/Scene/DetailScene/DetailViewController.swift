//
//  DetailViewController.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/26/23.
//

import Combine
import ProgressHUD
import UIKit
import youtube_ios_player_helper

class DetailViewController: UIViewController {

    @IBOutlet weak var channelIcon: UIImageView!
    @IBOutlet weak var playerView: YTPlayerView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var channelLabel: UILabel!
    @IBOutlet weak var viewCountLabel: UILabel!
    @IBOutlet weak var subscriberLabel: UILabel!

    @IBOutlet weak var tableView: UITableView!

    var viewModel: DetailViewModel?

    private var comments: [CommentModel] = []
    private var cancellables: Set<AnyCancellable> = []
    private let input: PassthroughSubject<DetailViewModelImp.Input, Never> = .init()


    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        setupTableView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        channelIcon.layer.cornerRadius = channelIcon.bounds.height / 2
    }
}

// MARK: Private Functions
extension DetailViewController {

    private func setupBindings() {
        viewModel?.bind(input.eraseToAnyPublisher())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] events in
                guard let self = self else { return }
                switch events {
                case .presentViewState(let model):
                    self.populateData(model)
                case .presentComments(let comments):
                    self.comments = comments
                    self.tableView.reloadData()
                case .showLoading(let isLoading, let message):
                    self.showLoading(isLoading, message: message)
                case .showError(let errorMessage):
                    ProgressHUD.showError(errorMessage, delay: 3)
                }
            }.store(in: &cancellables)
        input.send(.requestViewState)
    }

    private func populateData(_ model: VideoModel) {
        playerView.delegate = self
        playerView.load(withVideoId: model.id ?? .empty)
        titleLabel.text = model.title
        channelLabel.text = model.channelTitle.truncated(limit: 20)
        viewCountLabel.text = Int(model.viewCount ?? .empty)?.getFormattedString("views")
        subscriberLabel.text = Int(model.subscribers ?? .empty)?.getFormattedString("subscribers")
        if let url = URL(string: model.channelIcon ?? .empty) {
            channelIcon.af.setImage(withURL: url)
        }
    }

    private func setupTableView() {
        tableView.register(R.nib.commentCell)
        let headerNib = UINib(nibName: CommentHeaderView.cellIdentifier, bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: CommentHeaderView.cellIdentifier)
    }
}


// MARK: - UITableViewDataSource
extension DetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.commentCell.identifier,
                                                       for: indexPath) as? CommentCell else { return UITableViewCell() }
        cell.config(model: comments[indexPath.row])
        return cell
    }
}

extension DetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        if indexPath.row == (comments.count) - 1 {
            input.send(.loadMore)
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "CommentHeaderView")
        return header
    }
}

// MARK: - YTPlayerViewDelegate
extension DetailViewController: YTPlayerViewDelegate {

    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        playerView.playVideo()
    }
}

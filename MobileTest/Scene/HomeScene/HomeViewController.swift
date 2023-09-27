//
//  HomeViewController.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/26/23.
//

import Combine
import UIKit
import ProgressHUD

class HomeViewController: UITableViewController {

    private var cancellables: Set<AnyCancellable> = []
    private let input: PassthroughSubject<HomeViewModelImp.Input, Never> = .init()
    private var data: [VideoModel] = []
    private let viewModel: HomeViewModel = HomeViewModelImp()

    private var searchBarController: UISearchController = {
        let sb = UISearchController()
        sb.searchBar.placeholder = "Enter the movie name"
        sb.searchBar.searchBarStyle = .minimal
        sb.searchBar.barStyle = .black
        return sb
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTapListener()
        setupBindings()
        setupTableView()
        searchBarController.searchBar.delegate = self
        navigationItem.searchController = searchBarController
        navigationItem.hidesSearchBarWhenScrolling = true
    }
}

// MARK: - Private Functions
extension HomeViewController {

    private func setupTapListener() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tapGesture)
    }

    private func setupBindings() {
        viewModel.bind(input.eraseToAnyPublisher())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] events in
                guard let self = self else { return }
                switch events {
                case .fetchDataSuccess(let data):
                    self.data = data
                    self.tableView.reloadData()
                case .fetchSearchDataSuccess(let data):
                    self.data = data
                    self.tableView.reloadData()
                case .showError(let error):
                    ProgressHUD.showError(error, delay: 3)
                case .scrollToTop:
                    self.tableView.contentOffset = CGPoint(x: 0, y: -100)
                case .showLoading(let isLoading, let message):
                    if isLoading {
                        ProgressHUD.show(message, interaction: false)
                    } else {
                        ProgressHUD.dismiss()
                        self.refreshControl?.endRefreshing()
                    }
                }
            }.store(in: &cancellables)
        input.send(.fetchData(isForce: true))
    }

    private func setupTableView() {
        tableView.register(R.nib.homeTableViewCell)
        setupRefreshControl()
    }

    private func setupRefreshControl() {
        refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }

    @objc private func didTap() {
        view.endEditing(true)
    }

    @objc private func refreshData() {
        input.send(.fetchData(isForce: true))
    }
}

// MARK: - UITableViewDataSource
extension HomeViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: R.reuseIdentifier.homeTableViewCell.identifier
        ) as? HomeTableViewCell else { return UITableViewCell() }
        let model = data[indexPath.row]
        let cellViewModel = HomeCellViewModelImp(model: model)
        cell.configure(cellViewModel)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension HomeViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        if indexPath.row == (data.count) - 1 {
            input.send(.loadMore)
        }
    }
}

// MARK: - UISearchBarDelegate
extension HomeViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        input.send(.fetchSearch(searchBar.text ?? .empty))
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        tableView.contentOffset = CGPoint(x: 0, y: -100)
        input.send(.cancelSearch)
    }
}

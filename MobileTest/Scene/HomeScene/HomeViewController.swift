//
//  HomeViewController.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/26/23.
//

import Combine
import UIKit
import ProgressHUD

class HomeViewController: UIViewController {

    private enum Constants {
        static let searchFieldKey = "searchField"
        static let clearButtonKey = "_clearButton"
    }

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var cancelButton: UIButton!

    private var cancellables: Set<AnyCancellable> = []
    private let input: PassthroughSubject<HomeViewModelImp.Input, Never> = .init()
    private var data: [VideoModel] = []
    private let viewModel: HomeViewModel = HomeViewModelImp()

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        setupTapListener()
        setupSearchBar()
        setupBindings()
        setupTableView()
    }

    @IBAction func didTapCancel(_ sender: UIButton) {
        searchBar.text?.removeAll()
        input.send(.fetchData)
    }
}

// MARK: - Private Functions
extension HomeViewController {

    private func setupTapListener() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tapGesture)
    }

    private func setupSearchBar() {
        if let searchTextField = searchBar.value(forKey: Constants.searchFieldKey) as? UITextField,
           let clearButton = searchTextField.value(forKey: Constants.clearButtonKey) as? UIButton {
             clearButton.addTarget(self, action: #selector(didTapClearBtn), for: .touchUpInside)
        }
        searchBar.barTintColor = UIColor.white
        searchBar.setBackgroundImage(UIImage.init(), for: UIBarPosition.any, barMetrics: UIBarMetrics.default)
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
                    self.cancelButton.isHidden = true
                case .fetchSearchDataSuccess(let data):
                    self.data = data
                    self.tableView.reloadData()
                    self.cancelButton.isHidden = false
                case .showError(let error):
                    ProgressHUD.showError(error)
                case .showLoading(let isLoading):
                    if isLoading {
                        ProgressHUD.show()
                    } else {
                        ProgressHUD.dismiss()
                    }
                }
            }.store(in: &cancellables)
        input.send(.fetchData)
    }

    private func setupTableView() {
        tableView.register(R.nib.homeTableViewCell)
    }

    @objc private func didTap() {
        view.endEditing(true)
    }

    @objc private func didTapClearBtn() {
        input.send(.fetchData)
    }
}

// MARK: - UITableViewDataSource
extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - UISearchBarDelegate
extension HomeViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        input.send(.fetchSearch(searchBar.text ?? .empty))
        searchBar.resignFirstResponder()
    }
}

//
//  HomeCoordinator.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/27/23.
//

import Foundation
import UIKit

protocol HomeCoordinator {
    func goToDetails(_ model: VideoModel)
}

class HomeCoordinatorImp: HomeCoordinator {

    private var navigationController: UINavigationController?

    init(_ navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    func goToDetails(_ model: VideoModel) {
        guard let detailVC = R.storyboard.detail.detailViewController() else { return }
        let viewModel = DetailViewModelImp(model: model)
        detailVC.viewModel = viewModel
        
        navigationController?.present(detailVC, animated: true)
    }
}

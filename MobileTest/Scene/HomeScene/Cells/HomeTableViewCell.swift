//
//  HomeTableViewCell.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/26/23.
//

import AlamofireImage
import UIKit

class HomeTableViewCell: UITableViewCell {

    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var channelIcon: UIImageView!
    @IBOutlet weak var channelName: UILabel!
    @IBOutlet weak var viewCountLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        channelIcon.layer.cornerRadius = channelIcon.bounds.height / 2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        channelIcon.image = nil
        thumbnail.image = nil
    }

    func configure(_ viewModel: HomeCellViewModel) {
        titleLabel.text = viewModel.title
        channelName.text = viewModel.channel
        viewCountLabel.text = viewModel.viewCount
        setupImages(viewModel)
    }
}


// MARK: - Private Functions
extension HomeTableViewCell {
    private func setupImages(_ viewModel: HomeCellViewModel) {
        if let thumbnailUrl = viewModel.thumbnail {
            self.thumbnail.af.setImage(withURL: thumbnailUrl)
        }

        if let channelThumbnailUrl = viewModel.channelIcon {
            self.channelIcon.af.setImage(withURL: channelThumbnailUrl)
        }
    }
}

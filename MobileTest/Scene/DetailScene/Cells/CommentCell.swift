//
//  CommentCell.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/27/23.
//

import UIKit

class CommentCell: UITableViewCell {

    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        userImage.layer.cornerRadius = userImage.bounds.height / 2
    }


    override func prepareForReuse() {
        super.prepareForReuse()
        userImage.image = nil
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func config(model: CommentModel) {
        usernameLabel.text = model.authorDisplayName
        commentLabel.text = model.textOriginal

        if let url = URL(string: model.authorProfileImageUrl ?? .empty) {
            userImage.af.setImage(withURL: url)
        }
    }
}

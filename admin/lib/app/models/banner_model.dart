class BannerModel {
  String? id;
  String? bannerName;
  String? bannerDescription;
  String? image;
  bool? isOfferBanner;
  bool? isEnable;
  String? offerText;
  String? cmsId;
  String? cmsKey;
  String? bannerType;

  BannerModel({this.id, this.bannerName, this.bannerDescription, this.image, this.isOfferBanner, this.isEnable, this.offerText, this.cmsId, this.cmsKey, this.bannerType});

  BannerModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    bannerName = json['bannerName'];
    bannerDescription = json['bannerDescription'];
    image = json['image'];
    isOfferBanner = json['isOfferBanner'];
    isEnable = json['isEnable'] ?? true;
    offerText = json['offerText'];
    cmsId = json['cmsId'];
    cmsKey = json['cmsKey'];
    bannerType = json['bannerType'];
  }

  @override
  String toString() {
    return 'BannerModel{id: $id, bannerName: $bannerName, bannerDescription: $bannerDescription, image: $image, isOfferBanner: $isOfferBanner, isEnable: $isEnable, offerText: $offerText, cmsId: $cmsId, cmsKey: $cmsKey, bannerType: $bannerType}';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['bannerName'] = bannerName;
    data['bannerDescription'] = bannerDescription;
    data['image'] = image;
    data['isOfferBanner'] = isOfferBanner;
    data['isEnable'] = isEnable ?? true;
    data['offerText'] = offerText;
    data['cmsId'] = cmsId;
    data['cmsKey'] = cmsKey;
    data['bannerType'] = bannerType;
    return data;
  }
}

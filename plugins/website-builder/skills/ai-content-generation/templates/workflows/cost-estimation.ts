// Cost estimation for AI generation campaigns

export interface CampaignEstimate {
  num_images: number;
  num_videos?: number;
  num_content_pieces: number;
  image_quality?: 'sd' | 'hd';
}

export function calculateCostEstimate(campaign: CampaignEstimate) {
  const imageCost = campaign.num_images * (campaign.image_quality === 'hd' ? 0.08 : 0.04);
  const videoCost = (campaign.num_videos || 0) * 0.50;
  const contentCost = campaign.num_content_pieces * 0.01;

  return {
    image_cost: imageCost,
    video_cost: videoCost,
    content_cost: contentCost,
    total_cost: imageCost + videoCost + contentCost
  };
}

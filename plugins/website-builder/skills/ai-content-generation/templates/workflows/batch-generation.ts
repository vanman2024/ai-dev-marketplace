// Batch content and image generation workflow

import { generateMarketingContent } from '../typescript/content-generator';
import { batchGenerateImages } from '../typescript/image-generator';

export async function generateProductPages(products: Array<{name: string; category: string}>) {
  for (const product of products) {
    const content = await generateMarketingContent({
      prompt: `Product description for ${product.name} in ${product.category}`,
      max_tokens: 500
    });
    console.log(`Generated content for ${product.name}`);
  }
}

export async function generateCampaignAssets(campaign: {name: string; themes: string[]}) {
  const imagePrompts = campaign.themes.map(theme => ({
    prompt: `${campaign.name} campaign, ${theme} theme, professional`,
    quality: 'hd' as const
  }));

  const images = await batchGenerateImages(imagePrompts);
  return { campaign: campaign.name, images };
}

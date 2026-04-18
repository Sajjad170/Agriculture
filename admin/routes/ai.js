const express = require('express');
const { db } = require('../db');
const router = express.Router();

const cropRules = {
  wheat: {
    diseases: {
      'rust': { pesticide: 'Mancozeb 80WP', fertilizer: 'Urea (46% N)', tip: 'Yellow/orange pustules on leaves indicate rust disease. Apply fungicide early morning.' },
      'aphids': { pesticide: 'Imidacloprid 200SL', fertilizer: 'DAP (18-46-0)', tip: 'Aphid colonies under leaves. Spray in cool hours to protect beneficial insects.' },
      'loose smut': { pesticide: 'Mancozeb 80WP', fertilizer: 'Zinc Sulphate', tip: 'Treat seeds before sowing. Burn infected plants to prevent spread.' },
      'weed': { pesticide: 'Glyphosate 41%', fertilizer: 'Urea (46% N)', tip: 'Apply weed killer before crop emerges. Do not spray on crop leaves.' },
      'yellowing': { pesticide: null, fertilizer: 'Zinc Sulphate', tip: 'Zinc deficiency causes yellowing. Apply zinc sulphate foliar spray.' },
    },
    general: { pesticide: 'Chlorpyrifos 40EC', fertilizer: 'Urea (46% N)', tip: 'Apply nitrogen at tillering stage for best wheat yield. Irrigate after urea application.' }
  },
  rice: {
    diseases: {
      'blast': { pesticide: 'Mancozeb 80WP', fertilizer: 'Potassium Sulphate', tip: 'Rice blast appears as diamond-shaped lesions. Avoid excessive nitrogen.' },
      'stem borer': { pesticide: 'Chlorpyrifos 40EC', fertilizer: 'Urea (46% N)', tip: 'Dead hearts in vegetative stage. Apply pesticide when egg masses appear.' },
      'brown planthopper': { pesticide: 'Imidacloprid 200SL', fertilizer: 'DAP (18-46-0)', tip: 'Hopperburn causes circular patches. Do not over-apply nitrogen.' },
      'weed': { pesticide: 'Glyphosate 41%', fertilizer: 'DAP (18-46-0)', tip: 'Weeds compete for nutrients. Control during first 30 days after transplanting.' },
      'yellowing': { pesticide: null, fertilizer: 'Zinc Sulphate', tip: 'Iron/zinc deficiency in rice is common. Apply zinc before transplanting.' },
    },
    general: { pesticide: 'Mancozeb 80WP', fertilizer: 'DAP (18-46-0)', tip: 'Apply DAP at transplanting and urea in splits for maximum rice yield.' }
  },
  cotton: {
    diseases: {
      'whitefly': { pesticide: 'Imidacloprid 200SL', fertilizer: 'Potassium Sulphate', tip: 'Whiteflies transmit leaf curl virus. Spray underside of leaves. Monitor weekly.' },
      'bollworm': { pesticide: 'Lambda-cyhalothrin', fertilizer: 'Urea (46% N)', tip: 'Pink bollworm causes square/boll shedding. Use pheromone traps for monitoring.' },
      'leaf curl': { pesticide: 'Imidacloprid 200SL', fertilizer: 'Potassium Sulphate', tip: 'Virus transmitted by whitefly. Plant resistant varieties and control vector.' },
      'aphids': { pesticide: 'Chlorpyrifos 40EC', fertilizer: 'DAP (18-46-0)', tip: 'Aphid honeydew causes sooty mold. Spray in morning, natural enemies help control.' },
      'weed': { pesticide: 'Glyphosate 41%', fertilizer: 'Urea (46% N)', tip: 'Weed control critical in first 6 weeks. Use mulching to reduce weed pressure.' },
    },
    general: { pesticide: 'Imidacloprid 200SL', fertilizer: 'Potassium Sulphate', tip: 'Potassium is critical for cotton fiber quality. Apply in 3-4 splits throughout season.' }
  },
  maize: {
    diseases: {
      'fall armyworm': { pesticide: 'Lambda-cyhalothrin', fertilizer: 'Urea (46% N)', tip: 'Check whorls for frass. Apply pesticide in whorl stage for best control.' },
      'stem borer': { pesticide: 'Chlorpyrifos 40EC', fertilizer: 'DAP (18-46-0)', tip: 'Granular pesticide in whorl is most effective. Apply at 3-4 leaf stage.' },
      'rust': { pesticide: 'Mancozeb 80WP', fertilizer: 'Potassium Sulphate', tip: 'Common and southern rust. Spray when 5% leaf area is affected.' },
      'weed': { pesticide: 'Glyphosate 41%', fertilizer: 'Urea (46% N)', tip: 'Critical weed-free period is 0-6 weeks. Two weedings are recommended.' },
      'yellowing': { pesticide: null, fertilizer: 'Urea (46% N)', tip: 'Nitrogen deficiency causes V-shaped yellowing from leaf tip. Apply urea immediately.' },
    },
    general: { pesticide: 'Chlorpyrifos 40EC', fertilizer: 'Urea (46% N)', tip: 'Split nitrogen application (50% at sowing, 50% at knee height) improves yield 20%.' }
  }
};

function getRecommendation(crop, problem) {
  const cropLower = crop.toLowerCase().replace(/[^a-z]/g, '');
  const problemLower = problem.toLowerCase();

  let matchedCrop = null;
  for (const key of Object.keys(cropRules)) {
    if (cropLower.includes(key) || key.includes(cropLower)) { matchedCrop = key; break; }
  }

  if (!matchedCrop) {
    return {
      pesticide: 'Chlorpyrifos 40EC',
      fertilizer: 'Compost (Organic)',
      tip: 'For best results, consult a local agricultural extension officer. Organic compost improves soil health for any crop.',
      confidence: 'low'
    };
  }

  const rules = cropRules[matchedCrop];
  let matchedDisease = null;
  for (const disease of Object.keys(rules.diseases)) {
    if (problemLower.includes(disease) || disease.includes(problemLower.split(' ')[0])) {
      matchedDisease = disease; break;
    }
  }

  const recommendation = matchedDisease ? rules.diseases[matchedDisease] : rules.general;
  const confidence = matchedDisease ? 'high' : 'medium';

  // Get full product details from DB
  let pesticide = null, fertilizer = null;
  if (recommendation.pesticide) {
    pesticide = db.prepare("SELECT * FROM products WHERE name LIKE ? AND type='pesticide' AND status='active' LIMIT 1").get('%' + recommendation.pesticide.split(' ')[0] + '%');
  }
  if (recommendation.fertilizer) {
    fertilizer = db.prepare("SELECT * FROM products WHERE name LIKE ? AND type='fertilizer' AND status='active' LIMIT 1").get('%' + recommendation.fertilizer.split(' ')[0] + '%');
  }

  return {
    crop: matchedCrop,
    problem: matchedDisease || 'general',
    pesticide: pesticide || { name: recommendation.pesticide, price: 'See shop' },
    fertilizer: fertilizer || { name: recommendation.fertilizer, price: 'See shop' },
    tip: recommendation.tip,
    confidence
  };
}

router.post('/recommend', (req, res) => {
  const { crop, problem } = req.body;
  if (!crop) return res.status(400).json({ error: 'Crop type is required' });
  const result = getRecommendation(crop, problem || '');
  res.json(result);
});

router.get('/crops', (req, res) => {
  res.json(Object.keys(cropRules).map(c => c.charAt(0).toUpperCase() + c.slice(1)));
});

module.exports = router;

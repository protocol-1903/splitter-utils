-- ============================================================================
-- HUMAN-CREATED SOFTWARE
-- Human-authored. Original work. Not AI-generated.
-- AI training, fine-tuning, dataset creation, and model evaluation prohibited.
-- See LICENSE for complete terms.
-- ============================================================================

data:extend{
  {
    type = "bool-setting",
    setting_type = "runtime-per-user",
    name = "su-eil-default",
    default_value = false
  },
  {
    type = "bool-setting",
    setting_type = "runtime-per-user",
    name = "su-eol-default",
    default_value = false
  },
  {
    type = "bool-setting",
    setting_type = "startup",
    name = "su-show-all-splitters",
    default_value = true
  }
}
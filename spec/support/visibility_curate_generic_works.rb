# frozen_string_literal: true
WORK_WITH_EMORY_HIGH_VISIBILITY = {
  id:                            '111-321',
  has_model_ssim:                ['CurateGenericWork'],
  title_tesim:                   ['Work with Emory High visibility'],
  thumbnail_path_ss:             ['/downloads/111-321?file=thumbnail'],
  hasRelatedImage_ssim:          ['111-456'],
  edit_access_group_ssim:        ["admin"],
  read_access_group_ssim:        ["registered"],
  visibility_ssi:                ['authenticated'],
  visibility_group_ssi:          "Log In Required",
  human_readable_visibility_ssi: "Emory High Download"

}.freeze

WORK_WITH_PUBLIC_VISIBILITY = {
  id:                            '222-321',
  has_model_ssim:                ['CurateGenericWork'],
  title_tesim:                   ['Work with Open Access'],
  thumbnail_path_ss:             ['/downloads/222-321?file=thumbnail'],
  hasRelatedImage_ssim:          ['222-456'],
  edit_access_group_ssim:        ["admin"],
  read_access_group_ssim:        ["public"],
  visibility_ssi:                ['open'],
  visibility_group_ssi:          "Public",
  human_readable_visibility_ssi: "Public"
}.freeze

WORK_WITH_PUBLIC_LOW_VIEW_VISIBILITY = {
  id:                            '333-321',
  has_model_ssim:                ['CurateGenericWork'],
  title_tesim:                   ['Work with Public Low Resolution'],
  thumbnail_path_ss:             ['/downloads/333-321?file=thumbnail'],
  hasRelatedImage_ssim:          ['333-456'],
  edit_access_group_ssim:        ["admin"],
  read_access_group_ssim:        ["low_res"],
  visibility_ssi:                ['low_res'],
  visibility_group_ssi:          "Public",
  human_readable_visibility_ssi: "Public Low View"
}.freeze

WORK_WITH_EMORY_LOW_VISIBILITY = {
  id:                            '444-321',
  has_model_ssim:                ['CurateGenericWork'],
  title_tesim:                   ['Work with Emory Low visibility'],
  thumbnail_path_ss:             ['/downloads/444-321?file=thumbnail'],
  hasRelatedImage_ssim:          ['444-456'],
  edit_access_group_ssim:        ["admin"],
  read_access_group_ssim:        ["emory_low"],
  visibility_ssi:                ["emory_low"],
  visibility_group_ssi:          "Log In Required",
  human_readable_visibility_ssi: "Emory Low Download"
}.freeze

WORK_WITH_ROSE_HIGH_VISIBILITY = {
  id:                            '555-321',
  has_model_ssim:                ['CurateGenericWork'],
  title_tesim:                   ['Work with Rose High View visibility'],
  thumbnail_path_ss:             ['/downloads/555-321?file=thumbnail'],
  hasRelatedImage_ssim:          ['555-456'],
  edit_access_group_ssim:        ["admin"],
  read_access_group_ssim:        ["rose_high"],
  visibility_ssi:                ['rose_high'],
  visibility_group_ssi:          "Reading Room Specific",
  human_readable_visibility_ssi: "Rose High View"
}.freeze

WORK_WITH_PRIVATE_VISIBILITY = {
  id:                            '666-321',
  has_model_ssim:                ['CurateGenericWork'],
  title_tesim:                   ['Work with Private visibility'],
  thumbnail_path_ss:             ['/downloads/666-321?file=thumbnail'],
  hasRelatedImage_ssim:          ['666-456'],
  edit_access_group_ssim:        ["admin"],
  visibility_ssi:                ["restricted"],
  human_readable_visibility_ssi: "Private"
}.freeze

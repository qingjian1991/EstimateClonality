# A modified package of EstimateClonality

EstimateClonality is an R package which uses read count and copy number information to temporally and clonally dissect SNVs, written by Nicholas McGranahan (nicholas.mcgranahan@cancer.org.uk).

This version fixes some issues in the original code and makes a little optimization.

## Change blogs

### Changes (2022-05-07)

1. add some annotations.
2. add GD annotations.

For the genome doubling (function *genome.doub.sig*), the NULL hypothesis is that the evolution of high-ploidy results from a process of successive partial amplifications (independent amplifications between chromosomal arms) and the alternative hypothesis is that the evolution of tumor karyotypes results from whole-genome doubling (doubling all chromosomal at a time).

References:

1. Dewhurst, S. M., McGranahan, N., Burrell, R. A., Rowan, A. J., Gronroos, E., Endesfelder, D., . . . Swanton, C. (2014). Tolerance of whole-genome doubling propagates chromosomal instability and accelerates cancer genome evolution. Cancer Discov, 4(2), 175-185. doi:10.1158/2159-8290.CD-13-0285

2. Carter, S. L., Cibulskis, K., Helman, E., McKenna, A., Shen, H., Zack, T., . . . Getz, G. (2012). Absolute quantification of somatic DNA alterations in human cancer. Nat Biotechnol, 30(5), 413-421. doi:10.1038/nbt.2203


### Previous changes

1. The original R package is not compatible with sequenza version 3.0. Now the earlyORlate() function is compatible.
2. Added support for FACETS and CNVKIT (non ASCAT data).
3. Part of the code is simplified.

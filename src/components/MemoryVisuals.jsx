import React from 'react';

const rotations = ['-4deg', '3deg', '-2deg', '4deg', '-3deg'];

export function PolaroidPhoto({ image, alt = '', caption, rotation = '-3deg', size = 'md', depth = 2, tape = false, handwritten = false, className = '' }) {
  return <figure className={`mk-polaroid mk-polaroid--${size} ${handwritten ? 'mk-polaroid--handwritten' : ''} ${className}`} style={{ '--mk-rotation': rotation, '--mk-depth': depth }}>
    {tape && <span className="mk-tape" aria-hidden="true"/>}
    <img src={image} alt={alt}/>
    {caption && <figcaption>{caption}</figcaption>}
  </figure>;
}

export function PhotoStack({ photos, className = '', label }) {
  const displayedPhotos = photos.slice(0, 5);
  return <div className={`mk-photo-stack ${className}`} aria-label={label} role={label ? 'group' : undefined}>
    {displayedPhotos.map((photo, index) => <PolaroidPhoto key={`${photo.image}-${index}`} {...photo} size={photo.size || 'sm'} rotation={photo.rotation || rotations[index]} depth={photo.depth ?? index + 1}/>)}</div>;
}

export function PhotoStrip({ photos, label = 'Memory photographs', className = '' }) {
  return <section className={`mk-photo-strip ${className}`} aria-label={label}>
    {photos.map((photo, index) => <PolaroidPhoto key={`${photo.image}-${index}`} {...photo} size={photo.size || 'strip'} rotation={photo.rotation || rotations[index % rotations.length]} depth={photo.depth ?? 1}/>)}</section>;
}

export function PaperNote({ children, tone = 'cream', rotation = '-3deg', className = '' }) {
  return <aside className={`mk-paper-note mk-paper-note--${tone} ${className}`} style={{ '--mk-note-rotation': rotation }}>{children}</aside>;
}

export function GiftTag({ children, tone = 'cream', rotation = '8deg', className = '' }) {
  return <span className={`mk-gift-tag mk-gift-tag--${tone} ${className}`} style={{ '--mk-tag-rotation': rotation }}>{children}</span>;
}

export function TapeSticker({ kind = 'tape', tone = 'rose', className = '' }) {
  return <span className={`mk-sticker mk-sticker--${kind} mk-sticker--${tone} ${className}`} aria-hidden="true">{kind === 'sticker' ? '✦' : ''}</span>;
}

export function EditorialImageBlock({ image, alt, eyebrow, title, caption, className = '' }) {
  return <figure className={`mk-editorial-image ${className}`}>
    <img src={image} alt={alt}/>
    {(eyebrow || title || caption) && <figcaption>{eyebrow && <span>{eyebrow}</span>}{title && <strong>{title}</strong>}{caption && <p>{caption}</p>}</figcaption>}
  </figure>;
}
